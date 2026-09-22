// How long a workout took — and the one case where the honest answer is that
// nobody knows.
//
// A session stores when it started and when it finished, and for anything
// logged in this app the difference between them is the length. Importing
// broke that assumption: StrengthLog's export records when the workout *file*
// was last closed rather than when training stopped, so a session left open
// until the next one was started exports an end days later. Those ends are
// thrown away on the way in (see `plausibleEnd`), which leaves a finished
// session whose start and end are the same instant.
//
// That is not a workout of zero length. It is a workout whose length the file
// never recorded, and the two have to read differently: "0 min" on a session
// with eighteen logged sets is a confident statement of something false.
//
// The rule lives here, in one place, because four screens ask the question —
// the workout summary, the Home card, the year grid and the training totals —
// and three different answers across them would be worse than any one of them
// being wrong.

/// How long a session took, or null when that is not known.
///
/// Null has three causes, and every caller treats them the same way — by
/// saying nothing rather than printing a number:
///
///  - [completedAt] is null: the session is still running.
///  - It is before [startedAt]: the clock moved, and the difference is not a
///    duration.
///  - It equals [startedAt]: the length was never recorded. This is what an
///    import writes when the file's end time was not usable, and what a
///    session started and finished inside one second looks like, since the
///    database stores whole seconds.
///
/// A session with no known length still *happened*. Nothing here decides
/// whether it counts as training — that is `completedAt != null`, and it stays
/// true either way.
Duration? sessionLength(DateTime startedAt, DateTime? completedAt) {
  if (completedAt == null) return null;
  if (!completedAt.isAfter(startedAt)) return null;
  return completedAt.difference(startedAt);
}
