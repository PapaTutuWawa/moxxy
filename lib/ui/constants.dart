import "dart:ui";
import "package:flutter/widgets.dart";

const Radius RADIUS_LARGE = Radius.circular(10);
const Radius RADIUS_SMALL = Radius.circular(4);

const double TEXTFIELD_RADIUS_REGULAR = 15;
const double TEXTFIELD_RADIUS_CONVERSATION = 20;
const EdgeInsetsGeometry TEXTFIELD_PADDING_REGULAR = EdgeInsets.only(top: 4.0, bottom: 4.0, left: 8.0, right: 8.0);
const EdgeInsetsGeometry TEXTFIELD_PADDING_CONVERSATION = EdgeInsets.all(10);

const int PRIMARY_COLOR_HEX_RGBO = 0xffcf4aff;
const Color PRIMARY_COLOR = Color(PRIMARY_COLOR_HEX_RGBO);

const Color BUBBLE_COLOR_SENT = PRIMARY_COLOR;
const Color BUBBLE_COLOR_RECEIVED = Color.fromRGBO(44, 62, 80, 1.0);

const double PADDING_VERY_LARGE = 64.0;

const double FONTSIZE_TITLE = 40;
const double FONTSIZE_SUBTITLE = 25;
const double FONTSIZE_APPBAR = 20;
const double FONTSIZE_BODY = 15;
const double FONTSIZE_SUBBODY = 10;
