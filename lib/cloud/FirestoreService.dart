/*
This class represents a way to communicate with firestore  database
 */
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';


final CollectionReference employeesCollection = Firestore.instance.collection('employees');
