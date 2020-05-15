import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:basic_utils/basic_utils.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:async';
import 'dart:convert';

void main() => runApp(MyApp());

class DogBreed {
  final String name;
  final String image;

  DogBreed({this.name, this.image});

  factory DogBreed.fromJson(String name, String image) {
    return DogBreed(
      name: name,
      image: image
    );
  }
}

Future<List<String>> fetchDogBreedImages(String breedname) async {
  http.Response response;
  List<String> images = List<String>();
  List<String> name = breedname.split(' ');

  if (name.length == 1) {
    response = await http.get('https://dog.ceo/api/breed/${name[0].toLowerCase()}/images/random/30');
  } else {
    response = await http.get('https://dog.ceo/api/breed/${name[1].toLowerCase()}/${name[0].toLowerCase()}/images/random/30');
  }

  if (response.statusCode == 200) {
    Map<String, dynamic> breedImage = json.decode(response.body);
    for (var brdImage in breedImage['message']) {
      images.add(brdImage.toString());
    }
    return images;
    
  } else {
    throw Exception('Failed to load dog breed image');
  }
}

Future<String> fetchDogBreedImage(String breedname) async {
  http.Response response;
  List<String> name = breedname.split(' ');
  if (name.length == 1) {
    response = await http.get('https://dog.ceo/api/breed/${name[0].toLowerCase()}/images/random');
  } else {
    response = await http.get('https://dog.ceo/api/breed/${name[1].toLowerCase()}/${name[0].toLowerCase()}/images/random');
  }

  if (response.statusCode == 200) {
    Map<String, dynamic> breedImage = json.decode(response.body);
    return breedImage['message'];
  } else {
    throw Exception('Failed to load dog breed image');
  }
}

Future<List<String>> fetchDogBreeds() async {
  final response = await http.get('https://dog.ceo/api/breeds/list/all');
  List<String> dogBreeds = List<String>();

  if (response.statusCode == 200) {
    Map<String, dynamic> listOfDogBreeds = json.decode(response.body);
    
    listOfDogBreeds['message'].forEach((k,v) async => {
      if (v.length == 0) {
        dogBreeds.add(StringUtils.capitalize(k))
      } else {
        for (var brd in v) {
          dogBreeds.add(StringUtils.capitalize(brd) + ' ' + StringUtils.capitalize(k))
        }
      }
    });
    return dogBreeds;    
  } else {
    throw Exception('Failed to load dog breeds library');
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tindog',
      theme: ThemeData(primaryColor: Colors.lime),
      home: DogBreeds(),
    );
  }
}

class DogBreeds extends StatefulWidget {
  @override
  DogBreedsState createState() => DogBreedsState();
}

class DogBreedsState extends State<DogBreeds> {
  Future<List<String>> dogBreedsFuture;
  List<String> dogBreedList = List<String>();
  final _biggerFont = const TextStyle(fontSize: 18.0);

  @override
  void initState() {
    super.initState();
    dogBreedsFuture = fetchDogBreeds();
  }

  Widget _breedImages(String breedName) {
    return FutureBuilder(builder: (context, dogImages) {
      if (dogImages.hasData) {
        return Center (
          child: Container(
            child: CarouselSlider(
              options: CarouselOptions(
                aspectRatio: 2.0,
                enlargeCenterPage: true,
                enableInfiniteScroll: true,
                autoPlay: true,
              ),
              items: Iterable<int>.generate(5).toList().map((item) => Container(
                child: Center(
                  child: Image.network(dogImages.data[item], fit: BoxFit.cover, width: 800)
                ),
              )).toList(), 
            )
          ),
        );
      }
      return Center(child: CircularProgressIndicator());
    },
    future: fetchDogBreedImages(breedName));
  }
  
  void _breedPage(String breedName) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (BuildContext context){
        return Scaffold(         // Add 6 lines from here...
          appBar: AppBar(
            title: Text(breedName),
          ),
          body: _breedImages(breedName)
        ); 
      })
    );
  }

  Widget _buildRow(String breedName) {
  //final bool alreadySaved = _saved.contains(pair);
    return FutureBuilder(builder: (context, breedImage){
      if(breedImage.hasData) {
        return GestureDetector (
          child: Card(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: Column (
              children: <Widget>[
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(breedImage.data),
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.topCenter,
                    )
                  ),
                ),
                ListTile(
                  title: Center(
                    child: Text(
                      breedName,
                      style: _biggerFont,
                    )
                  ),
                ),
              ],
            )
          ),
          onTap: () {
            _breedPage(breedName);
          },
        );
      }
      return Card(child: Container(
        padding: EdgeInsets.fromLTRB(10,10,10,0),
        height: 220,
        width: double.maxFinite,
        child: Center(child: CircularProgressIndicator())));
    },
    future: fetchDogBreedImage(breedName),);
    
  }

  Widget _dogBreedList() {
    return FutureBuilder(builder: (context, dogBreeds) {
      if(dogBreeds.hasData) {
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemBuilder: (context, i) {
          //if (i.isOdd) return Divider();

          // final index = i ~/ 2;
          // if (index >= dogBreedList.length) {
            dogBreedList.addAll(dogBreeds.data);
          //}
          return _buildRow(dogBreedList[i]);
        });
      }
      return Center(child: CircularProgressIndicator());
    },
    future: dogBreedsFuture,);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dog Breeds Library')
      ),
      body: _dogBreedList(),
    );
  }
}
