import 'package:supabase_flutter/supabase_flutter.dart';

const String kSupabaseUrl = 'https://hmtnewymuanlvdbfdmrh.supabase.co';
const String kSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhtdG5ld3ltdWFubHZkYmZkbXJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxODE3ODcsImV4cCI6MjA3OTc1Nzc4N30.midJmbMWczpGBRnrXHzjNS1xkeu7wowT9JTWKeocGyU';

Future<void> initSupabase() async {
  await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseAnonKey);
}
