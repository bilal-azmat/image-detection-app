import 'package:flutter/material.dart';
import 'package:page_view_dot_indicator/page_view_dot_indicator.dart';
import 'custom_button.dart';
import 'home_screen.dart';


class OnBoardModel {
  String title ;
  String subTitle ;
  String image ;

  OnBoardModel({
    required this.title,
    required this.subTitle,
    required this.image
  }) ;
}

class IntroScreen extends StatefulWidget {
  const IntroScreen({Key? key}) : super(key: key);

  @override
  State<IntroScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<IntroScreen> {
  int currentIndex = 0 ;


  List<OnBoardModel> onBoardList = [
    OnBoardModel(
        title: 'Bridge the Gap',
        subTitle: 'Communicate effortlessly with sign language detection and translation.',
        image: "assets/images/hand_sign.jpeg"
    ),
    OnBoardModel(
        title: 'Sign Speak',
        subTitle: 'Your real-time sign language interpreter for seamless communication.',
        image: "assets/images/hand.png"
    ),
    OnBoardModel(
        title: 'Handy Talk',
        subTitle: 'Empowering connections through sign language recognition technology.',
        image: "assets/images/hand_talk.jpeg"
    ),
  ] ;

  final PageController pageController = PageController(initialPage: 0);

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SafeArea(
        child: PageView.builder(
          controller: pageController,
          itemCount: onBoardList.length,
          onPageChanged: (int index) {
            setState(() {
              currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            // setState(() {
            //   currentIndex = index ;
            // });
            return buildPage(currentIndex);
          },
        ),
      ),
    ) ;
  }

  Widget buildPage(int index)
  {
    var height = MediaQuery.of(context).size.height ;
    var width = MediaQuery.of(context).size.width ;

    return Container(
      height: height,
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          //title and subtitle
          Container(
            padding: const EdgeInsets.all(10),
            width: width,
            height: 209,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //title
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  //margin: const EdgeInsets.only(top: 40),
                  width: width,
                  child: Text(
                    onBoardList[index].title,
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.w700,


                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                //sub_title
                Container(
                  //color: Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  margin: const EdgeInsets.only(top: 20),
                  width: width,
                  child: Text(
                    onBoardList[index].subTitle,
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        color: Colors.black,

                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          //page indicator
          Container(
            height: 30,
            child: buildPageIndicator(),
          ),

          //image and button
          Expanded(
            child: Stack(
              children: [
                //images
                Container(
                  width: width,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                        fit: BoxFit.fill,
                        image: AssetImage(onBoardList[index].image)
                    ),
                  ),
                ),

                //button
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    width: width * 0.9,
                    child: CustomButton(
                      onTap: (){
                        if(currentIndex < 2)
                        {
                          setState(() {
                            currentIndex++ ;
                          });
                          pageController.jumpToPage(currentIndex);
                        }
                        else
                        {
                          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context)=>CameraScreen()));
                          print('Get Started') ;
                        }
                      },
                      title: index == 2 ?  'Get Started' : 'Next',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ) ;
  }

  Widget buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: PageViewDotIndicator(
        currentItem: currentIndex,
        count: onBoardList.length,
        unselectedColor: Colors.grey,
        selectedColor: Colors.blue,
        duration: const Duration(milliseconds: 200),
        boxShape: BoxShape.circle,
      ),
    );
  }
}