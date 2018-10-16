import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audioplayer/audioplayer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

main() {
  runApp(new MaterialApp(
      theme: new ThemeData(
          fontFamily:
          defaultTargetPlatform == TargetPlatform.android ? 'SF-Medium' : ''),
    title: 'Guessify',
    home: new StartScreen(),
  ));
}

final String clientId = 'b24efc40c2e348eaa51550f7d66e6069';
final String clientSecret = 'bb0ee6c903a94975957f52900511dbc9';

String auth;
var client = new http.Client();

String accessToken;

int _selectedGenre = 0;



const List<String> Playlists = const <String>[
  'spotifycharts:37i9dQZEVXbMDoHDwVN2tF',
  'spotify:37i9dQZF1DXcBWIGoYBM5M',
  'spotify:37i9dQZF1DX0XUsuxWHRQd',
  'spotify:37i9dQZF1DX4SBhb3fqCJd',
  'spotify:37i9dQZF1DXcF6B6QPhFDv',
  'spotify:37i9dQZF1DX2Nc3B70tvx0',
  'spotify:37i9dQZF1DX4dyzvuaRJ0n',
  'spotify:37i9dQZF1DWWEJlAGA9gs0',
  'spotify:37i9dQZF1DXbITWG1ZJKYt',
  'spotify:37i9dQZF1DX504r1DvyvxG',
  'spotify:37i9dQZF1DX1lVhptIYRda',
  'spotify:37i9dQZF1DXbSbnqxMTGx9',
  'spotify:37i9dQZF1DWTcqUzwhNmKv',
  'spotify:37i9dQZF1DWWvhKV4FBciw',
  'spotify:37i9dQZF1DXa9wYJr1oMFq'
];

const List<String> Genres = const <String>[
  'Top 50',
  'Pop',
  'Hip-Hop',
  'R&B',
  'Rock',
  'Indie',
  'Electronic/Dance',
  'Classical',
  'Jazz',
  'Folk & Americana',
  'Country',
  'Reggae',
  'Metal',
  'Funk/Soul',
  'Punk',
];



class StartScreen extends StatefulWidget {
  @override
  State createState() => new StartScreenState();
}

class StartScreenState extends State<StartScreen> {
  Widget _buildBottomPickerGenre() {
    final FixedExtentScrollController scrollController =
    new FixedExtentScrollController(initialItem: _selectedGenre);

    return new Container(
      height: 216.0,
      color: CupertinoColors.white,
      child: new DefaultTextStyle(
        style: const TextStyle(
          color: CupertinoColors.black,
          fontSize: 22.0,
        ),
        child: new GestureDetector(
          // Blocks taps from propagating to the modal sheet and popping.
          onTap: () {},
          child: new SafeArea(
            child: new CupertinoPicker(
              scrollController: scrollController,
              itemExtent: 32.0,
              backgroundColor: CupertinoColors.white,
              onSelectedItemChanged: (int index) {
                setState(() {
                  _selectedGenre = index;
                });
              },
              children: new List<Widget>.generate(Genres.length, (int index) {
                return new Center(
                  child: new Text(Genres[index]),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Colors.white,
      /*appBar: new AppBar(
        brightness: Brightness.light,
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        centerTitle: true,
        title: new Text(
          '',
          style: new TextStyle(color: new Color(0xFF343A40), fontSize: 18.0),
        ),
      ),*/
      body: Container(padding: EdgeInsets.all(20.0),child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,children: <Widget>[
        Padding(padding: new EdgeInsets.only(top: 100.0)),
        Text(
          'Guessify',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.amber,
              fontSize: 50.0,
              fontWeight: FontWeight.bold,
          ),
        ),
        Padding(padding: new EdgeInsets.only(top: 150.0)),
        new GestureDetector(
          onTap: () async {
            await showModalBottomSheet<Null>(
              context: context,
              builder: (BuildContext context) {
                return _buildBottomPickerGenre();
              },
            );
          },
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child:Text(
            'Selected Genre: ' + Genres[_selectedGenre],
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.black,
                fontSize: 25.0,
                ),
          ),),),
        Padding(padding: new EdgeInsets.only(top: 150.0)),
        CupertinoButton(child: Text('Let\'s play!'), onPressed: (){
          Navigator.of(context).pushReplacement(
            new CupertinoPageRoute(builder: (context) => new MainScreen()),
          );
        },color: Colors.green,)
      ],),),);
  }

}


class MainScreen extends StatefulWidget {
  @override
  State createState() => new MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  var playlist;
  var artist;
  var related1;
  var related2;
  var related3;
  var trackPreview;
  var loaded = false;
  int seconds = 30;
  int correct = 0;
  int total = 0;
  var randomizedArtists = List<String>();
  var playedSongs = List<String>();
  AudioPlayer audioPlayer;
  double posx = 100.0;
  double posy = 100.0;
  String feedback = "";

  bool _visibleEmoji = false;

  void onTapDown(BuildContext context, TapDownDetails details) {
    print('${details.globalPosition}');
    final RenderBox box = context.findRenderObject();
    final Offset localOffset = box.globalToLocal(details.globalPosition);

    //posx = localOffset.dx - 5;
    //posy = localOffset.dy - 25;
  }

  void moveAndFadeOutEmoji(bool correct) async {
    if (correct)
      feedback = 'Correct!👌';
    else
      feedback = 'Wrong!👎';
    setState(() {
      _visibleEmoji = true;
      loaded = false;
    });
    audioPlayer.stop();
    await new Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      //loaded = false;
      _visibleEmoji = false;
    });
    await new Future.delayed(const Duration(milliseconds: 500));
    if (total == 10)
      goToEnd();
    else
      playGame();
  }

  void getAuthToken() async {
    var auth = BASE64.encode('$clientId:$clientSecret'.codeUnits);
    var headers = {'Authorization': 'Basic $auth'};
    var body = {'grant_type': 'client_credentials'};

    var response = await client.post('https://accounts.spotify.com/api/token',
        headers: headers, body: body);

    accessToken = json.decode(response.body)['access_token'];

    //print(accessToken);

    getGlobalPlaylist();
  }

  void getGlobalPlaylist() async {
    var selectedPlaylist = Playlists[_selectedGenre];
    var splitPlaylist = selectedPlaylist.split(':');

    print('Selected Genre =' + Genres[_selectedGenre] + ' playlist is = ' + splitPlaylist[1]);

    var response = await client.get(
        'https://api.spotify.com/v1/users/${splitPlaylist[0]}/playlists/${splitPlaylist[1]}',
        headers: {'Authorization': 'Bearer $accessToken'});
    playlist = json.decode(response.body);
    //print(playlist['tracks']);

    playGame();
  }

  void playGame() async {
    var rng = new Random();

    var songNumber = rng.nextInt(playlist['tracks']['total']);

    print('Total = ' + playlist['tracks']['total'].toString());
    //print(playlist['tracks']['items']);

    var track = playlist['tracks']['items'][songNumber]['track'];

    artist = track['artists'][0]['name'];

    var artistId = track['artists'][0]['id'];

    var trackId = track['id'];
    if (playedSongs.contains(trackId)) {
      playGame();
      return;
    }
    //var trackName = track['name'];
    trackPreview = track['preview_url'];

    var response = await client.get(
        'https://api.spotify.com/v1/artists/$artistId/related-artists',
        headers: {'Authorization': 'Bearer $accessToken'});
    var related = json.decode(response.body);

    // print(related);

    if (related['artists'] != null &&
        (related['artists'] as List<dynamic>).length > 0) {
      //ERROR WHEN EMPTY
      related1 = related['artists'][0]['name'];
      related2 = related['artists'][1]['name'];
      related3 = related['artists'][2]['name'];
    } else {
      related1 = null;
      related2 = null;
      related3 = null;
    }

    if (trackPreview == null || related3 == null)
      playGame();
    else {
      playedSongs.add(trackId);
      setState(() {
        loaded = true;
      });
    }
  }

  @override
  void initState() {
    getAuthToken();
    audioPlayer = new AudioPlayer();
    super.initState();
  }

  @override
  void dispose() {
    //_positionSubscription.cancel();
    //_audioPlayerStateSubscription.cancel();
    audioPlayer.stop();
    super.dispose();
  }

  void goToEnd() {
    Navigator.of(context).pushReplacement(
          new CupertinoPageRoute(builder: (context) => new EndScreen(correct)),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (loaded) {
      /* Fluttertoast.showToast(
          msg: artist,
          toastLength: Toast.LENGTH_SHORT,
          timeInSecForIos: 1
      );*/
      if (audioPlayer.state != AudioPlayerState.PLAYING) {
        randomizedArtists = List<String>();
        print('Playing: ' + trackPreview.toString());
        audioPlayer.play(trackPreview);

        print('Artist: ' + artist.toString());
        var rng = new Random();

        var number = rng.nextInt(4);

        if (number == 0) {
          randomizedArtists.add(artist);
          randomizedArtists.add(related1);
          randomizedArtists.add(related2);
          randomizedArtists.add(related3);
        } else if (number == 1) {
          randomizedArtists.add(related1);
          randomizedArtists.add(artist);
          randomizedArtists.add(related2);
          randomizedArtists.add(related3);
        } else if (number == 2) {
          randomizedArtists.add(related1);
          randomizedArtists.add(related2);
          randomizedArtists.add(artist);
          randomizedArtists.add(related3);
        } else if (number == 3) {
          randomizedArtists.add(related1);
          randomizedArtists.add(related2);
          randomizedArtists.add(related3);
          randomizedArtists.add(artist);
        }
      }
    }
    return new Scaffold(
      backgroundColor: Colors.white,
      /*appBar: new AppBar(
        brightness: Brightness.light,
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        centerTitle: true,
        title: new Text(
          '',
          style: new TextStyle(color: new Color(0xFF343A40), fontSize: 18.0),
        ),
      ),*/
      body: new Container(
        child: new Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Column(
              children: <Widget>[
                Padding(padding: new EdgeInsets.only(top: 70.0)),
                Text(
                  'Who\'s the artist?',
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 25.0,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  Genres[_selectedGenre],
                  style: TextStyle(
                      color: Colors.black54,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: new EdgeInsets.only(top: 50.0, bottom: 50.0),
                  child: new Center(
                    child: AnimatedOpacity(
                      opacity: _visibleEmoji ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 500),
                      child: new Text(
                        feedback,
                        style: TextStyle(fontSize: 30.0),
                      ),
                    ),
                  ),
                ),
                loaded == false
                    ? Center(child: CircularProgressIndicator())
                    : Column(
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Padding(padding: new EdgeInsets.only(left: 25.0)),
                              Expanded(
                                child: new CupertinoButton(
                                    padding: const EdgeInsets.all(13.0),
                                    color: Colors.amber,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: new Text(
                                        randomizedArtists[0],
                                        style: new TextStyle(
                                            fontSize: 16.0,
                                            color: Colors.black),
                                      ),
                                    ),
                                    onPressed: () async {
                                      if (randomizedArtists[0] == artist)
                                        ++correct;
                                      moveAndFadeOutEmoji(
                                          randomizedArtists[0] == artist);
                                      ++total;
                                    }),
                              ),
                              Padding(padding: new EdgeInsets.only(left: 25.0)),
                              Expanded(
                                child: new CupertinoButton(
                                    padding: const EdgeInsets.all(13.0),
                                    color: Colors.amber,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: new Text(
                                        randomizedArtists[1],
                                        style: new TextStyle(
                                            fontSize: 16.0,
                                            color: Colors.black),
                                      ),
                                    ),
                                    onPressed: () async {
                                      if (randomizedArtists[1] == artist)
                                        ++correct;
                                      moveAndFadeOutEmoji(
                                          randomizedArtists[1] == artist);
                                      ++total;
                                    }),
                              ),
                              Padding(padding: new EdgeInsets.only(left: 25.0)),
                            ],
                          ),
                          Padding(padding: new EdgeInsets.only(top: 50.0)),
                          Row(
                            children: <Widget>[
                              Padding(padding: new EdgeInsets.only(left: 25.0)),
                              Expanded(
                                child: new CupertinoButton(
                                    padding: const EdgeInsets.all(13.0),
                                    color: Colors.amber,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: new Text(
                                        randomizedArtists[2],
                                        style: new TextStyle(
                                            fontSize: 16.0,
                                            color: Colors.black),
                                      ),
                                    ),
                                    onPressed: () async {
                                      if (randomizedArtists[2] == artist)
                                        ++correct;
                                      moveAndFadeOutEmoji(
                                          randomizedArtists[2] == artist);
                                      ++total;
                                    }),
                              ),
                              Padding(padding: new EdgeInsets.only(left: 25.0)),
                              Expanded(
                                child: new CupertinoButton(
                                    padding: const EdgeInsets.all(13.0),
                                    color: Colors.amber,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: new Text(
                                        randomizedArtists[3],
                                        style: new TextStyle(
                                            fontSize: 16.0,
                                            color: Colors.black),
                                      ),
                                    ),
                                    onPressed: () async {
                                      if (randomizedArtists[3] == artist)
                                        ++correct;
                                      moveAndFadeOutEmoji(
                                          randomizedArtists[3] == artist);
                                      ++total;
                                    }),
                              ),
                              Padding(padding: new EdgeInsets.only(left: 25.0)),
                            ],
                          ),
                        ],
                      ),
              ],
            ),
            total == 0
                ? Container()
                : new Align(
                    alignment: Alignment.bottomCenter,
                    child: new Padding(
                      padding: const EdgeInsets.only(bottom: 150.0),
                      child: Text(
                        'You\'ve got $correct right out of $total',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}


class EndScreen extends StatelessWidget{
  int correctAnswers;

  EndScreen(this.correctAnswers);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        backgroundColor: Colors.white,
        /*appBar: new AppBar(
        brightness: Brightness.light,
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        centerTitle: true,
        title: new Text(
          '',
          style: new TextStyle(color: new Color(0xFF343A40), fontSize: 18.0),
        ),
      ),*/
        body:  Container(padding: EdgeInsets.all(20.0),child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,children: <Widget>[
      Padding(padding: new EdgeInsets.only(top: 100.0)),
      Text(
        'Round Finished',
        textAlign: TextAlign.center,
        style: TextStyle(
            color: Colors.amber,
            fontSize: 45.0,
            fontWeight: FontWeight.bold),
      ),
      Padding(padding: new EdgeInsets.only(top: 150.0)),
      Text(
        'Your score is:\n $correctAnswers / 10',
        textAlign: TextAlign.center,
        style: TextStyle(
            color: Colors.amber,
            fontSize: 30.0,
            fontWeight: FontWeight.bold),
      ),
      Padding(padding: new EdgeInsets.only(top: 150.0)),
          CupertinoButton(child: Text('Try again'), onPressed: (){
            Navigator.of(context).pushReplacement(
              new CupertinoPageRoute(builder: (context) => new MainScreen()),
            );
          },color: Colors.pink,),
      Padding(padding: new EdgeInsets.only(top: 50.0)),
      CupertinoButton(child: Text('Go to menu'), onPressed: (){
        Navigator.of(context).pushReplacement(
          new CupertinoPageRoute(builder: (context) => new StartScreen()),
        );
      },color: Colors.deepPurpleAccent,)
        ],),),);
  }


}


