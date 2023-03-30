import 'package:const_annotation/const_annotation.dart';
import 'package:json_annotation/json_annotation.dart';
part 'person.g.dart';

@dartDTO
const String userModel = '''{
"id": "1",
"title": "The Catcher in the Rye",
"author": {
    "id": "100",
    "name": "J.D. Salinger",
    "birthYear": 1919,
    "deathYear": 2010
},
"genres": [
    "Fiction",
    "Coming-of-age"
],
"publication": {
    "publisher": "Little, Brown and Company",
    "year": 1951,
    "edition": "1st",
    "language": "English"
}
}''';
