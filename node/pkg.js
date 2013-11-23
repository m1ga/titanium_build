#!/usr/bin/env node

var cmdr = require('commander'),
	cp = require('child_process'),
	exec = cp.exec,
	fs = require('fs'),
	moment = require('moment'),
	path = require('path'),
	spawn = cp.spawn,
	startTime = new Date;

cmdr.option('-d, --dir', 'Node project dir')
	.parse(process.argv);

console.info('Node.js Module Packager\n');

console.info('Command: "' + process.argv.join('" "') + '"');
console.info('Environment:');
console.info(process.env);
console.info();

var dir = cmdr.dir || process.cwd(),
	pkgJsonFile = path.join(dir, 'package.json');

// check that there's a package.json
if (!fs.existsSync(pkgJsonFile)) {
	console.error('ERROR: Couldn\'t find package.json\n');
	process.exit(1);
}

// read and parse the package.json
var origPkgJson = fs.readFileSync(pkgJsonFile),
	pkgJson;
try {
	pkgJson = JSON.parse(origPkgJson);
} catch (ex) {
	console.error(ex);
	process.exit(1);
}

var origVersion = pkgJson.version,
	version = origVersion;
if (!version) {
	console.error('ERROR: package.json missing version\n');
}

// remove any old builds
fs.readdirSync(dir).forEach(function (name) {
	var file = path.join(dir, name);
	if (fs.existsSync(file) && name.indexOf(pkgJson.name + '-') == 0 && /\.tgz$/.test(name)) {
		console.info('Removing old build "' + file + '"');
		fs.unlinkSync(file);
	}
});

console.info('Packaging module "' + pkgJson.name + '" v' + pkgJson.version);

version = version.split('.').concat([0, 0]).slice(0, 3).join('.') + '-v' + moment().format('YYYYMMDDHHmmss');

// update the version in the package.json
console.info('Setting version to "' + version + '"');
pkgJson.version = version;
fs.writeFileSync(pkgJsonFile, JSON.stringify(pkgJson, null, '\t'));

// package the module
exec('npm pack', function (err, stdout, stderr) {
	// restore the original package.json contents
	console.info('Restoring original package.json');
	fs.writeFileSync(pkgJsonFile, origPkgJson);

	if (err) {
		console.error('ERROR: ' + err);
		console.error(stderr);
		process.exit(1);
	}

	var branch = process.env.GIT_BRANCH.split('/').pop(),
		src = path.join(dir, stdout.trim().split('\n').shift().trim()),
		dest = path.join(dir, pkgJson.name + '-' + version.replace(/\-/g, '.') + '.tgz');

	fs.renameSync(src, dest);

	console.info('Output file: ' + dest);

	var commonDir = path.join(__dirname, '..', 'common'),
		cleanerArgs = [
			path.join(commonDir, 's3_cleaner.py'),
			pkgJson.name,
			branhc
		];

	console.info('\nExecuting: python "' + cleanerArgs.join('" "') + '"');

	var cleaner = spawn('python', cleanerArgs, { stdio: 'inherit' });

	cleaner.on('close', function (code) {
		if (code) {
			console.error('\nERROR: s3_cleaner failed\n');
			process.exit(1);
		}

		var uploaderArgs = [
			path.join(commonDir, 's3_uploader.py'),
			pkgJson.name,
			dest,
			branch,
			process.env.GIT_COMMIT,
			process.env.BUILD_URL
		];

		console.info('\nExecuting: python "' + uploaderArgs.join('" "') + '"');

		var uploader = spawn('python', uploaderArgs, { stdio: 'inherit' });

		uploader.on('close', function (code) {
			if (code) {
				console.error('\nERROR: s3_uploader failed\n');
				process.exit(1);
			}

			console.info('\nRemoving ' + dest);
			fs.unlinkSync(dest);

			console.info('Completed successfully in ' + (((new Date).getTime() - startTime.getTime()) / 1000) + ' seconds\n');
		});
	});
});
