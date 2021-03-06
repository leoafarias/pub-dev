// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:gcloud/db.dart';
import 'package:test/test.dart';

import 'package:pub_dev/frontend/handlers/documentation.dart';
import 'package:pub_dev/package/models.dart';
import 'package:pub_dev/shared/urls.dart';

import '../../frontend/handlers/_utils.dart';
import '../../shared/handlers_test_utils.dart';
import '../../shared/test_models.dart';
import '../../shared/test_services.dart';

void main() {
  group('path parsing', () {
    void testUri(String rqPath, String package, [String version, String path]) {
      final p = parseRequestUri(Uri.parse('$siteRoot$rqPath'));
      if (package == null) {
        expect(p, isNull);
      } else {
        expect(p, isNotNull);
        expect(p.package, package);
        expect(p.version, version);
        expect(p.path, path);
      }
    }

    test('bad prefix', () {
      testUri('/doc/pkg/latest/', null);
    });

    test('insufficient prefix', () {
      testUri('/documentation', null);
      testUri('/documentation/', null);
    });

    test('bad package name', () {
      testUri('/documentation//latest/', null);
      testUri('/documentation/<pkg>/latest/', null);
      testUri('/documentation/pkg with space/latest/', null);
    });

    test('no version specified', () {
      testUri('/documentation/angular', 'angular');
      testUri('/documentation/angular/', 'angular');
    });

    test('bad version', () {
      testUri('/documentation/pkg//', 'pkg');
      testUri('/documentation/pkg/first-release/', 'pkg');
      testUri('/documentation/pkg/1.2.3.4.5.6/', 'pkg');
    });

    test('version without path', () {
      testUri('/documentation/angular/4.0.0+2', 'angular', '4.0.0+2');
      testUri('/documentation/angular/4.0.0+2/', 'angular', '4.0.0+2',
          'index.html');
    });

    test('version with a path', () {
      testUri('/documentation/angular/4.0.0+2/subdir/', 'angular', '4.0.0+2',
          'subdir/index.html');
      testUri('/documentation/angular/4.0.0+2/file.html', 'angular', '4.0.0+2',
          'file.html');
      testUri('/documentation/angular/4.0.0+2/file.html', 'angular', '4.0.0+2',
          'file.html');
    });
  });

  group('dartdoc handlers', () {
    testWithServices('/documentation/flutter redirect', () async {
      await expectRedirectResponse(
        await issueGet('/documentation/flutter'),
        'https://docs.flutter.io/',
      );
    });

    testWithServices('/documentation/flutter/version redirect', () async {
      await expectRedirectResponse(
        await issueGet('/documentation/flutter/version'),
        'https://docs.flutter.io/',
      );
    });

    testWithServices('/documentation/foobar_pkg/bar redirect', () async {
      await expectRedirectResponse(
        await issueGet('/documentation/foobar_pkg/bar'),
        '/documentation/foobar_pkg/latest/',
      );
    });

    testWithServices('trailing slash redirect', () async {
      await expectRedirectResponse(await issueGet('/documentation/foobar_pkg'),
          '/documentation/foobar_pkg/latest/');
    });

    testWithServices('/documentation/foobar_pkg - no entry redirect', () async {
      await expectRedirectResponse(
          await issueGet('/documentation/foobar_pkg/latest/'),
          '/packages/foobar_pkg/versions');
    });

    testWithServices('/d/foobar_pkg/latest/ redirect', () async {
      await expectRedirectResponse(
          await issueGet('/documentation/foobar_pkg/latest/'),
          '/packages/foobar_pkg/versions');
    });

    testWithServices('/d/foobar_pkg/latest/unknown.html redirect', () async {
      await expectRedirectResponse(
          await issueGet('/documentation/foobar_pkg/latest/unknown.html'),
          '/packages/foobar_pkg/versions');
    });

    testWithServices('withheld package gets rejected', () async {
      final pkg = await dbService.lookupValue<Package>(foobarPkgKey);
      await dbService.commit(inserts: [pkg..isWithheld = true]);
      await expectNotFoundResponse(
          await issueGet('/documentation/foobar_pkg/latest/'));
    });
  });
}
