/*
=======================================================================================================================================
Pick Mode
=======================================================================================================================================
Purpose: The two separate picking jobs the app supports. A picker does one or the other, never both
         at once, and the two lists never overlap.

  customer - real customer orders. Picking sets qty to 0 and is freely reversible.
  amazon   - stock allocated to Amazon. Picking moves the item to the C3-Amazon staging area,
             which is what takes it off the list. Unpicking puts it back where it was found.
=======================================================================================================================================
*/

enum PickMode {
  customer,
  amazon;

  /// Value sent to the server as `pick_type`
  String get apiValue => name;

  /// Short label, for tags and inline references.
  String get displayName => this == PickMode.amazon ? 'Amazon' : 'Customer';

  /// The job in a picker's own words, for titles and the job switch.
  String get jobName =>
      this == PickMode.amazon ? 'Amazon stock' : 'Customer picks';
}
