/// Represents all supported high-level user intents in VAJRA 2.0.
enum VajraIntentType {
  conversation,
  question,
  memorySave,
  memoryQuery,
  memoryDelete,
  taskCreate,
  taskUpdate,
  taskComplete,
  taskDelete,
  planning,
  reminder,
  notification,
  study,
  search,
  navigation,
  action,
  profileUpdate,
  generalAssistance,
  unknown;

  static VajraIntentType fromString(String val) {
    final clean = val.trim().toLowerCase().replaceAll('_', '').replaceAll(' ', '');
    
    // Direct exact match
    for (final type in VajraIntentType.values) {
      if (type.name.toLowerCase() == clean) {
        return type;
      }
    }

    // Explicit Action & Creation commands take highest priority
    if (clean.contains('createtask') || clean.contains('addtask') || clean.contains('newtask') || clean.contains('taskcreate') || clean.contains('createstudyplan') || clean.contains('createaplan')) {
      return VajraIntentType.taskCreate;
    }
    if (clean.contains('completetask') || clean.contains('taskcomplete') || clean.contains('finishtask')) {
      return VajraIntentType.taskComplete;
    }
    if (clean.contains('remind') || clean.contains('reminder')) {
      return VajraIntentType.reminder;
    }
    if (clean.contains('rememberthat') || clean.contains('rememberthis') || clean.contains('remember') || clean.contains('memorysave') || clean.contains('savememory')) {
      return VajraIntentType.memorySave;
    }
    if (clean.contains('forget') || clean.contains('deletememory') || clean.contains('memorydelete')) {
      return VajraIntentType.memoryDelete;
    }
    if (clean.contains('whendoi') || clean.contains('whatdoi') || clean.contains('howdoi') || clean.contains('whatdoyouremember') || clean.contains('recall') || clean.contains('memoryquery')) {
      return VajraIntentType.memoryQuery;
    }
    if (clean.contains('planmy') || clean.contains('schedulemy') || clean.contains('studyplan') || clean.contains('planning')) {
      return VajraIntentType.planning;
    }
    if (clean.contains('teachme') || clean.contains('studymode') || clean.contains('startstudy') || clean.contains('study') || clean.contains('exam') || clean.contains('teach')) {
      return VajraIntentType.study;
    }
    if (clean.contains('open') || clean.contains('navigate') || clean.contains('takeme')) {
      return VajraIntentType.navigation;
    }
    if (clean.contains('profile')) {
      return VajraIntentType.profileUpdate;
    }
    if (clean.startsWith('what') || clean.startsWith('how') || clean.startsWith('why') || clean.startsWith('who')) {
      return VajraIntentType.question;
    }

    return VajraIntentType.conversation;
  }
}
