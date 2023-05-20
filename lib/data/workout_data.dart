import 'package:fitness_app/data/hive_database.dart';
import 'package:fitness_app/datetime/date_time.dart';
import 'package:fitness_app/models/exercise.dart';
import 'package:flutter/material.dart';
import '../models/workout.dart';

class WorkoutData extends ChangeNotifier {
  final db = HiveDatabase();

  List<Workout> workoutList = [
    Workout(
      name: "Biceps",
      exercises: [
        Exercise(
          name: "Biceps Curls",
          weight: '10',
          reps: '12',
          sets: '3',
        ),
      ],
    ),
    Workout(
      name: "Chest",
      exercises: [
        Exercise(
          name: "Bench Press",
          weight: '20',
          reps: '12',
          sets: '3',
        ),
      ],
    ),
  ];

  //if there are workouts already in database, then get that workout list, otherwise use default workout
  void initializeWorkoutList() {
    if (db.previousDataExists()) {
      workoutList = db.readFromDatabase();
    } else {
      db.saveToDatabase(workoutList);
    }

    //load heat map
    loadHeatMap();
  }

  //get the list of workouts
  List<Workout> getWorkoutList() {
    return workoutList;
  }

  //get length of given workout
  int numberOfExerciseInWorkout(String workoutName) {
    Workout relevantWorkout = getRelevantWorkout(workoutName);

    return relevantWorkout.exercises.length;
  }

  //add a workout
  void addWorkout(String name) {
    workoutList.add(Workout(name: name, exercises: []));

    notifyListeners();

    //save to database
    db.saveToDatabase(workoutList);
  }

  //add an exercise to a workout
  void addExercise(String workoutName, String exerciseName, String weight,
      String reps, String sets) {
    Workout relevantWorkout =
        workoutList.firstWhere((workout) => workout.name == workoutName);

    relevantWorkout.exercises.add(
      Exercise(
        name: exerciseName,
        weight: weight,
        reps: reps,
        sets: sets,
      ),
    );

    notifyListeners();
  }

  //check off exercise
  void checkOffExercise(String workoutName, String exerciseName) {
    // find the relevant workout and relevant exercise in that workout
    Exercise relevantExercise = getRelevantExercise(workoutName, exerciseName);

    //check off boolean to show user completed the exercise
    relevantExercise.isCompleted = !relevantExercise.isCompleted;

    notifyListeners();

    //save to database
    db.saveToDatabase(workoutList);

    //load heat map
    loadHeatMap();
  }

  //return relevant workout, given a workout name
  Workout getRelevantWorkout(String workoutName) {
    Workout relevantWorkout =
        workoutList.firstWhere((workout) => workout.name == workoutName);
    return relevantWorkout;
  }

  //return relevant exercise object, given a workout name + exercise name
  Exercise getRelevantExercise(String workoutName, String exerciseName) {
    //find relevant workout first
    Workout relevantWorkout = getRelevantWorkout(workoutName);

    //then find the relevant exercise in that workout
    Exercise relevantExercise = relevantWorkout.exercises
        .firstWhere((workout) => workout.name == workoutName);
    return relevantExercise;
  }

  //get start date
  String getStartDate() {
    return db.getStartDate();
  }

  Map<DateTime, int> heatMapDataSet = {};

  void loadHeatMap() {
    DateTime startDate = createDateTimeObject(getStartDate());

    //count the number of days to load
    int daysInBetween = DateTime.now().difference(startDate).inDays;

    //go from start date to today, and add each completion status to the dataset
    // "COMPLETION_STATUS_yyyymmdd" will be the key in the database
    for (int i = 0; i < daysInBetween + 1; i++) {
      String yyyymmdd =
          convertDateTimeToYYYYMMDD(startDate.add(Duration(days: 1)));

      //completion status 0 or 1
      int completionStatus = db.getCompletionStatus(yyyymmdd);

      //year
      int year = startDate.add(Duration(days: 1)).year;

      //month
      int month = startDate.add(Duration(days: 1)).month;

      //day
      int day = startDate.add(Duration(days: 1)).day;

      final percentForEachDay = <DateTime, int>{
        DateTime(year, month, day): completionStatus
      };

      //add to the heat map dataset
      heatMapDataSet.addEntries(percentForEachDay.entries);
    }
  }
}
