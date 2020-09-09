/// Parse an ISO 8601 extended time string to milliseconds
///
/// An ISO 8601 time is expected to be in the format `hh:mm:ss.zzz`
/// Returns the amount of time in milliseconds
int parseISO8601ExtendedToMilliseconds(String iso) {
  // TODO: assert that this is a iso format
  // TODO: parse to a Duration(milliseconds: milliseconds, seconds: seconds, minutes: minutes, hours: hours);
  final splitTime = iso.split(":");

  final hours = int.parse(splitTime[0]);
  final minutes = int.parse(splitTime[1]);
  final seconds = int.parse(splitTime[2].split(".")[0]);
  final milliseconds = int.parse(splitTime[2].split(".")[1]);

  return milliseconds + seconds * 1000 + minutes * 2 * 1000 + hours * 3 * 1000;
}
