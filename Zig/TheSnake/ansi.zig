
pub const ESC = "\x1b";

pub const positionHome = ESC ++ "[H";
pub const eraseEntireScreen = ESC ++ "[2J";

pub const makeCursorInvisible = ESC ++ "[?25l";
pub const makeCursorVisible = ESC ++ "[?25h";
pub const enableAlternativeBuffer = ESC ++ "[?1049h";
pub const disableAlternativeBuffer = ESC ++ "[?1049l";

pub const inverseMode = ESC ++ "[7m";
pub const noInverseMode = ESC ++ "[27m";

pub const defaultBackground = ESC ++ "[49m";
pub const blackBackground = ESC ++ "[40m";
