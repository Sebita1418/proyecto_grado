import 'package:flutter/material.dart';

import 'navigation_instruction.dart';

extension NavigationInstructionPresentation on NavigationInstruction {
  String get instructionText {
    final turn = switch (direction) {
      ManeuverDirection.left => 'Gira a la izquierda',
      ManeuverDirection.right => 'Gira a la derecha',
      ManeuverDirection.slightLeft => 'Gira ligeramente a la izquierda',
      ManeuverDirection.slightRight => 'Gira ligeramente a la derecha',
      ManeuverDirection.sharpLeft => 'Gira pronunciadamente a la izquierda',
      ManeuverDirection.sharpRight => 'Gira pronunciadamente a la derecha',
      ManeuverDirection.uturn => 'Da la vuelta',
      ManeuverDirection.straight => 'Continúa recto',
      ManeuverDirection.unknown => 'Sigue la ruta indicada',
    };
    final text = switch (type) {
      ManeuverType.depart => 'Inicia el recorrido',
      // La proximidad GPS, no un step futuro, confirma la llegada.
      ManeuverType.arrive => 'Llegada al destino',
      ManeuverType.merge || ManeuverType.onRamp => 'Incorpórate$_side',
      ManeuverType.fork => 'Toma la bifurcación$_side',
      ManeuverType.offRamp => 'Toma la salida$_side',
      ManeuverType.roundabout || ManeuverType.rotary =>
        exit == null
            ? 'Entra en la glorieta'
            : 'En la glorieta, toma la salida $exit',
      ManeuverType.exitRoundabout => 'Sal de la glorieta',
      ManeuverType.newName => 'Continúa por la vía',
      ManeuverType.turn ||
      ManeuverType.continueRoad ||
      ManeuverType.endOfRoad => turn,
      ManeuverType.unknown => 'Sigue la ruta indicada',
    };
    return streetName.trim().isEmpty || type == ManeuverType.arrive
        ? text
        : '$text en ${streetName.trim()}';
  }

  String get _side => switch (direction) {
    ManeuverDirection.left ||
    ManeuverDirection.slightLeft ||
    ManeuverDirection.sharpLeft => ' a la izquierda',
    ManeuverDirection.right ||
    ManeuverDirection.slightRight ||
    ManeuverDirection.sharpRight => ' a la derecha',
    _ => '',
  };

  IconData get instructionIcon {
    if (type == ManeuverType.unknown) return Icons.route;
    if (type == ManeuverType.arrive) return Icons.flag_outlined;
    if (type == ManeuverType.roundabout ||
        type == ManeuverType.rotary ||
        type == ManeuverType.exitRoundabout) {
      return Icons.roundabout_right;
    }
    if (type == ManeuverType.merge || type == ManeuverType.onRamp) {
      return Icons.merge;
    }
    return switch (direction) {
      ManeuverDirection.left => Icons.turn_left,
      ManeuverDirection.right => Icons.turn_right,
      ManeuverDirection.slightLeft => Icons.turn_slight_left,
      ManeuverDirection.slightRight => Icons.turn_slight_right,
      ManeuverDirection.sharpLeft => Icons.turn_sharp_left,
      ManeuverDirection.sharpRight => Icons.turn_sharp_right,
      ManeuverDirection.uturn => Icons.u_turn_left,
      _ => Icons.straight,
    };
  }
}
