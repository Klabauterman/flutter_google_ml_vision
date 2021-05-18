// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_ml_vision/google_ml_vision.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$GoogleVision', () {
    final List<MethodCall> log = <MethodCall>[];
    dynamic returnValue;

    setUp(() {
      GoogleVision.channel
          .setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);

        switch (methodCall.method) {
          case 'BarcodeDetector#detectInImage':
            return returnValue;
          case 'FaceDetector#processImage':
            return returnValue;
          case 'TextRecognizer#processImage':
            return returnValue;
          default:
            return null;
        }
      });
      log.clear();
      GoogleVision.nextHandle = 0;
    });

    group('$GoogleVisionImageMetadata', () {
      final TextRecognizer recognizer = GoogleVision.instance.textRecognizer();

      setUp(() {
        returnValue = <dynamic, dynamic>{
          'text': '',
          'blocks': <dynamic>[],
        };
      });

      test('default serialization', () async {
        final GoogleVisionImageMetadata metadata = GoogleVisionImageMetadata(
          rawFormat: 35,
          size: const Size(1, 1),
          planeData: <GoogleVisionImagePlaneMetadata>[
            GoogleVisionImagePlaneMetadata(
              bytesPerRow: 1000,
              height: 480,
              width: 480,
            ),
          ],
        );
        final GoogleVisionImage image =
            GoogleVisionImage.fromBytes(Uint8List(0), metadata);
        await recognizer.processImage(image);

        expect(log, <Matcher>[
          isMethodCall(
            'TextRecognizer#processImage',
            arguments: <String, dynamic>{
              'handle': 0,
              'type': 'bytes',
              'path': null,
              'bytes': Uint8List(0),
              'metadata': <String, dynamic>{
                'width': 1.0,
                'height': 1.0,
                'rotation': 0,
                'rawFormat': 35,
                'planeData': <dynamic>[
                  <String, dynamic>{
                    'bytesPerRow': 1000,
                    'height': 480,
                    'width': 480,
                  },
                ],
              },
              'options': <String, dynamic>{
                'modelType': 'onDevice',
              },
            },
          ),
        ]);
      });
    });

    group('$TextRecognizer', () {
      late TextRecognizer recognizer;
      final GoogleVisionImage image = GoogleVisionImage.fromFilePath(
        'empty',
      );

      setUp(() {
        recognizer = GoogleVision.instance.textRecognizer();
        final List<dynamic> elements = <dynamic>[
          <dynamic, dynamic>{
            'text': 'hello',
            'left': 1.0,
            'top': 2.0,
            'width': 3.0,
            'height': 4.0,
            'points': <dynamic>[
              <dynamic>[5.0, 6.0],
              <dynamic>[7.0, 8.0],
            ],
            'recognizedLanguages': <dynamic>[
              <dynamic, dynamic>{
                'languageCode': 'ab',
              },
              <dynamic, dynamic>{
                'languageCode': 'cd',
              }
            ],
          },
          <dynamic, dynamic>{
            'text': 'my',
            'left': 4.0,
            'top': 3.0,
            'width': 2.0,
            'height': 1.0,
            'points': <dynamic>[
              <dynamic>[6.0, 5.0],
              <dynamic>[8.0, 7.0],
            ],
            'recognizedLanguages': <dynamic>[],
          },
        ];

        final List<dynamic> lines = <dynamic>[
          <dynamic, dynamic>{
            'text': 'friend',
            'left': 5.0,
            'top': 6.0,
            'width': 7.0,
            'height': 8.0,
            'points': <dynamic>[
              <dynamic>[9.0, 10.0],
              <dynamic>[11.0, 12.0],
            ],
            'recognizedLanguages': <dynamic>[
              <dynamic, dynamic>{
                'languageCode': 'ef',
              },
              <dynamic, dynamic>{
                'languageCode': 'gh',
              }
            ],
            'elements': elements,
          },
          <dynamic, dynamic>{
            'text': 'how',
            'left': 8.0,
            'top': 7.0,
            'width': 4.0,
            'height': 5.0,
            'points': <dynamic>[
              <dynamic>[10.0, 9.0],
              <dynamic>[12.0, 11.0],
            ],
            'recognizedLanguages': <dynamic>[],
            'elements': <dynamic>[],
          },
        ];

        final List<dynamic> blocks = <dynamic>[
          <dynamic, dynamic>{
            'text': 'friend',
            'left': 13.0,
            'top': 14.0,
            'width': 15.0,
            'height': 16.0,
            'points': <dynamic>[
              <dynamic>[17.0, 18.0],
              <dynamic>[19.0, 20.0],
            ],
            'recognizedLanguages': <dynamic>[
              <dynamic, dynamic>{
                'languageCode': 'ij',
              },
              <dynamic, dynamic>{
                'languageCode': 'kl',
              }
            ],
            'lines': lines,
          },
          <dynamic, dynamic>{
            'text': 'hello',
            'left': 14.0,
            'top': 13.0,
            'width': 16.0,
            'height': 15.0,
            'points': <dynamic>[
              <dynamic>[18.0, 17.0],
              <dynamic>[20.0, 19.0],
            ],
            'recognizedLanguages': <dynamic>[],
            'lines': <dynamic>[],
          },
          <dynamic, dynamic>{
            'text': 'hey',
            'left': 14.0,
            'top': 13.0,
            'width': 16.0,
            'height': 15.0,
            'points': <dynamic>[
              <dynamic>[18.0, 17.0],
              <dynamic>[20.0, 19.0],
            ],
            'recognizedLanguages': <dynamic>[],
            'lines': <dynamic>[],
          },
        ];

        final dynamic visionText = <dynamic, dynamic>{
          'text': 'testext',
          'blocks': blocks,
        };

        returnValue = visionText;
      });

      group('$TextBlock', () {
        test('processImage', () async {
          final VisionText text = await recognizer.processImage(image);

          expect(text.blocks, hasLength(3));

          TextBlock block = text.blocks[0];
          // TODO(jackson): Use const Rect when available in minimum Flutter SDK
          // ignore: prefer_const_constructors
          expect(block.boundingBox, Rect.fromLTWH(13, 14, 15, 16));
          expect(block.text, 'friend');
          expect(block.cornerPoints, const <Offset>[
            Offset(17, 18),
            Offset(19, 20),
          ]);
          expect(block.recognizedLanguages[0], hasLength(2));
          expect(block.recognizedLanguages[0].languageCode, 'ij');
          expect(block.recognizedLanguages[1].languageCode, 'kl');

          block = text.blocks[1];
          // TODO(jackson): Use const Rect when available in minimum Flutter SDK
          // ignore: prefer_const_constructors
          expect(block.boundingBox, Rect.fromLTWH(14, 13, 16, 15));
          expect(block.text, 'hello');
          expect(block.cornerPoints, const <Offset>[
            Offset(18, 17),
            Offset(20, 19),
          ]);

          block = text.blocks[2];
          // TODO(jackson): Use const Rect when available in minimum Flutter SDK
          // ignore: prefer_const_constructors
          expect(block.boundingBox, Rect.fromLTWH(14, 13, 16, 15));
          expect(block.text, 'hey');
          expect(block.cornerPoints, const <Offset>[
            Offset(18, 17),
            Offset(20, 19),
          ]);
        });
      });

      group('$TextLine', () {
        test('processImage', () async {
          final VisionText text = await recognizer.processImage(image);

          TextLine line = text.blocks[0].lines[0];
          // TODO(jackson): Use const Rect when available in minimum Flutter SDK
          // ignore: prefer_const_constructors
          expect(line.boundingBox, Rect.fromLTWH(5, 6, 7, 8));
          expect(line.text, 'friend');
          expect(line.cornerPoints, const <Offset>[
            Offset(9, 10),
            Offset(11, 12),
          ]);
          expect(line.recognizedLanguages, hasLength(2));
          expect(line.recognizedLanguages[0].languageCode, 'ef');
          expect(line.recognizedLanguages[1].languageCode, 'gh');

          line = text.blocks[0].lines[1];
          // TODO(jackson): Use const Rect when available in minimum Flutter SDK
          // ignore: prefer_const_constructors
          expect(line.boundingBox, Rect.fromLTWH(8, 7, 4, 5));
          expect(line.text, 'how');
          expect(line.cornerPoints, const <Offset>[
            Offset(10, 9),
            Offset(12, 11),
          ]);
        });
      });

      group('$TextElement', () {
        test('processImage', () async {
          final VisionText text = await recognizer.processImage(image);

          TextElement element = text.blocks[0].lines[0].elements[0];
          // ignore: prefer_const_constructors
          expect(element.boundingBox, Rect.fromLTWH(1, 2, 3, 4));
          expect(element.text, 'hello');
          expect(element.cornerPoints, const <Offset>[
            Offset(5, 6),
            Offset(7, 8),
          ]);
          expect(element.recognizedLanguages, hasLength(2));
          expect(element.recognizedLanguages[0].languageCode, 'ab');
          expect(element.recognizedLanguages[1].languageCode, 'cd');

          element = text.blocks[0].lines[0].elements[1];
          // TODO(jackson): Use const Rect when available in minimum Flutter SDK
          // ignore: prefer_const_constructors
          expect(element.boundingBox, Rect.fromLTWH(4, 3, 2, 1));
          expect(element.text, 'my');
          expect(element.cornerPoints, const <Offset>[
            Offset(6, 5),
            Offset(8, 7),
          ]);
        });
      });

      test('processImage', () async {
        final VisionText text = await recognizer.processImage(image);

        expect(text.text, 'testext');
        expect(log, <Matcher>[
          isMethodCall(
            'TextRecognizer#processImage',
            arguments: <String, dynamic>{
              'handle': 0,
              'type': 'file',
              'path': 'empty',
              'bytes': null,
              'metadata': null,
              'options': <String, dynamic>{
                'modelType': 'onDevice',
              },
            },
          ),
        ]);
      });

      test('processImage no bounding box', () async {
        returnValue = <dynamic, dynamic>{
          'blocks': <dynamic>[
            <dynamic, dynamic>{
              'text': '',
              'points': <dynamic>[],
              'recognizedLanguages': <dynamic>[],
              'lines': <dynamic>[],
            },
          ],
        };

        final VisionText text = await recognizer.processImage(image);

        final TextBlock block = text.blocks[0];
        expect(block.boundingBox, null);
      });
    });
  });
}
