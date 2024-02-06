import 'package:flutter/material.dart';


class MyDeviceWidget extends StatelessWidget {
  final String name;
  final Function() onTap;
  bool isOnline;
  String radonValue;
  String unit;

  MyDeviceWidget({
    super.key,
    required this.onTap,
    required this.name,
    required this.isOnline,
    required this.radonValue,
    required this.unit
  });

  setIsOnline(bool onlineStatus){
    this.isOnline = onlineStatus;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 85,
        decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xffe5e5e5),width: 1.0),top: BorderSide(color: Color(0xffe5e5e5),width: 1.0))
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 20,),
                    SizedBox(
                      width: 160,
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize:  20,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    radonValue != "-1" ? RichText(
                        text: TextSpan(
                            text: radonValue,
                            style: TextStyle(
                                color: int.parse(radonValue) > 50 ? int.parse(radonValue) > 300 ? Color(0xfffd4c56) : Color(0xfffdca03) : Color(0xff0ace84),
                                fontSize: 20,
                                fontWeight: FontWeight.w600
                            ),
                            children: [
                              TextSpan(
                                text: " $unit",
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400
                                ),
                              )
                            ]
                        )
                    ) : const Text(""),
                    const SizedBox(width: 20,)
                  ],
                )
              ],
            ),
            const SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 20,),
                SizedBox(
                  width: 50,
                  height: 26,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      border: Border(
                        bottom: BorderSide(color: isOnline ? Color(0xffA5E658) : Colors.grey,),
                        top: BorderSide(color: isOnline ? Color(0xffA5E658)  : Colors.grey,),
                        right: BorderSide(color: isOnline ? Color(0xffA5E658)  : Colors.grey,),
                        left: BorderSide(color: isOnline ? Color(0xffA5E658)  : Colors.grey,),
                      )
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isOnline ? "online" : "offline",
                          style: TextStyle(color: isOnline ? Color(0xffA5E658)  : Colors.grey,),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}