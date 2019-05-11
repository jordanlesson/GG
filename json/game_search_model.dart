class Game{
  String gameName;
  List<Picture> gamePictures;
  List<int> gamePlatform;

  Game({
    this.gameName,
    this.gamePictures,
    this.gamePlatform
 });

  factory Game.fromJson(Map<String, dynamic> parsedJson){
    return Game(
      gameName: parsedJson['name'],
      gamePictures : parsedJson['gamePictures'],
      gamePlatform : parsedJson ['platforms']
    );
  }

}

class Picture {

  final String gamePictureURL;

  Picture({this.gamePictureURL});

  factory Picture.fromJson(Map<String, dynamic> parsedJson){
    return Picture(
      gamePictureURL: parsedJson['url']
    );
  }
}

