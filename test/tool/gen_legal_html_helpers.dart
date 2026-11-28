import 'dart:convert';
import 'dart:io';

Map<String, Object?> legalDoc(String lang, String kind) =>
    jsonDecode(File('assets/legal/$lang/$kind.json').readAsStringSync())
        as Map<String, Object?>;
