/*
=======================================================================================================================================
Shared Constants
=======================================================================================================================================
Purpose: Values that more than one route depends on and that must stay in sync between them.
=======================================================================================================================================
*/

// The staging area Amazon stock is moved to when it is picked.
// get_picks excludes this location from the Amazon list; set_amazon_picked moves stock into it.
// The Flutter app has a matching constant in lib/config/app_config.dart (amazonLocation).
const AMAZON_LOCATION = 'C3-Amazon';

// The allocation flag that marks stock as belonging to Amazon.
// Picking never changes this - only the location moves.
const AMAZON_ALLOCATION = 'amz';

module.exports = {
    AMAZON_LOCATION,
    AMAZON_ALLOCATION
};
