import 'package:flutter/material.dart';

class DependentSliders extends StatefulWidget {
  @override
  _DependentSlidersState createState() => _DependentSlidersState();
}

class _DependentSlidersState extends State<DependentSliders> {
  double _slider1Value = 0.0;
  double _slider2Value = 50.0;
  double _slider3Value = 75.0;

  void _updateSliders() {
    setState(() {
      _slider2Value = _slider1Value > _slider2Value ? _slider1Value : _slider2Value;
      _slider3Value = _slider2Value > _slider3Value ? _slider2Value : _slider3Value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dependent Sliders'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Slider(
              value: _slider1Value,
              onChanged: (newValue) {
                setState(() {
                  _slider1Value = newValue;
                  _updateSliders();
                });
              },
              min: 0,
              max: 100,
              label: 'Slider 1: $_slider1Value',
            ),
            Slider(
              value: _slider2Value,
              onChanged: (newValue) {
                setState(() {
                  _slider2Value = newValue;
                  _updateSliders();
                });
              },
              min: _slider1Value,
              max: _slider3Value,
              label: 'Slider 2: $_slider2Value',
            ),
            Slider(
              value: _slider3Value,
              onChanged: (newValue) {
                setState(() {
                  _slider3Value = newValue;
                });
              },
              min: _slider2Value,
              max: 1000,
              label: 'Slider 3: $_slider3Value',
            ),
          ],
        ),
      ),
    );
  }
}