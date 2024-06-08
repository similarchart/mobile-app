import 'package:flutter/material.dart';
import 'dart:math';

void validatePoints(List<Offset> originalPoints, List<Offset> points) {
  List<Offset> result = [];
  double? prevX;

  for (Offset point in originalPoints) {
    double currentX = point.dx;
    if (prevX == null || currentX > prevX) {
      result.add(point);
      prevX = currentX;
    }
  }

  points.clear();
  points.addAll(result);
}

void stretchGraphToFullWidth(BuildContext context, List<Offset> points) {
  double minX = points.reduce((a, b) => a.dx < b.dx ? a : b).dx;
  double maxX = points.reduce((a, b) => a.dx > b.dx ? a : b).dx;
  double width = context.size!.width;

  for (var i = 0; i < points.length; i++) {
    double normalizedX = (points[i].dx - minX) / (maxX - minX);
    points[i] = Offset(normalizedX * width, points[i].dy);
  }

  double minY = points.reduce((a, b) => a.dy < b.dy ? a : b).dy;
  double maxY = points.reduce((a, b) => a.dy > b.dy ? a : b).dy;
  double height = width;

  double marginTop =
  height - maxY > 0.2 * height ? 0.2 * height : height - maxY;
  double marginBottom = minY > 0.2 * height ? 0.2 * height : minY;

  for (var i = 0; i < points.length; i++) {
    double normalizedY = (points[i].dy - minY) / (maxY - minY);

    points[i] = Offset(points[i].dx,
        (normalizedY * (height - marginTop - marginBottom) + marginBottom));
  }
}

void interpolatePoints(String selectedSize, List<Offset> points) {
  double minX = points.map((p) => p.dx).reduce(min);
  double maxX = points.map((p) => p.dx).reduce(max);
  int numPoints = int.tryParse(selectedSize) ?? 128;
  double interval = (maxX - minX) / (numPoints - 1);

  List<Offset> newPoints = [points.first];
  for (int i = 1; i < numPoints - 1; i++) {
    double newX = minX + i * interval;
    Offset p1 =
    points.lastWhere((p) => p.dx <= newX, orElse: () => points.first);
    Offset p2 =
    points.firstWhere((p) => p.dx >= newX, orElse: () => points.last);

    double slope = (p2.dy - p1.dy) / (p2.dx - p1.dx);
    double newY = p1.dy + slope * (newX - p1.dx);
    newPoints.add(Offset(newX, newY));
  }
  newPoints.add(points.last);

  points.clear();
  points.addAll(newPoints);
}