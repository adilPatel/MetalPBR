import Foundation

/*
 * This file contains the ANSI keycodes used in key events. It was "borrowed"
 * from Apple's Carbon framework which is now deprecated. As a result, this
 * has been remastered for Swift while breaking away from old APIs
 */


/*
 *  Summary:
 *    Virtual keycodes
 *
 *  Discussion:
 *    These constants are the virtual keycodes defined originally in
 *    Inside Mac Volume V, pg. V-191. They identify physical keys on a
 *    keyboard. Those constants with "ANSI" in the name are labeled
 *    according to the key position on an ANSI-standard US keyboard.
 *    For example, kVK_ANSI_A indicates the virtual keycode for the key
 *    with the letter 'A' in the US keyboard layout. Other keyboard
 *    layouts may have the 'A' key label on a different physical key;
 *    in this case, pressing 'A' will generate a different virtual
 *    keycode.
 */
enum Alphanumerics: UInt16 {
    case VK_ANSI_A                    = 0x00
    case VK_ANSI_S                    = 0x01
    case VK_ANSI_D                    = 0x02
    case VK_ANSI_F                    = 0x03
    case VK_ANSI_H                    = 0x04
    case VK_ANSI_G                    = 0x05
    case VK_ANSI_Z                    = 0x06
    case VK_ANSI_X                    = 0x07
    case VK_ANSI_C                    = 0x08
    case VK_ANSI_V                    = 0x09
    case VK_ANSI_B                    = 0x0B
    case VK_ANSI_Q                    = 0x0C
    case VK_ANSI_W                    = 0x0D
    case VK_ANSI_E                    = 0x0E
    case VK_ANSI_R                    = 0x0F
    case VK_ANSI_Y                    = 0x10
    case VK_ANSI_T                    = 0x11
    case VK_ANSI_1                    = 0x12
    case VK_ANSI_2                    = 0x13
    case VK_ANSI_3                    = 0x14
    case VK_ANSI_4                    = 0x15
    case VK_ANSI_6                    = 0x16
    case VK_ANSI_5                    = 0x17
    case VK_ANSI_Equal                = 0x18
    case VK_ANSI_9                    = 0x19
    case VK_ANSI_7                    = 0x1A
    case VK_ANSI_Minus                = 0x1B
    case VK_ANSI_8                    = 0x1C
    case VK_ANSI_0                    = 0x1D
    case VK_ANSI_RightBracket         = 0x1E
    case VK_ANSI_O                    = 0x1F
    case VK_ANSI_U                    = 0x20
    case VK_ANSI_LeftBracket          = 0x21
    case VK_ANSI_I                    = 0x22
    case VK_ANSI_P                    = 0x23
    case VK_ANSI_L                    = 0x25
    case VK_ANSI_J                    = 0x26
    case VK_ANSI_Quote                = 0x27
    case VK_ANSI_K                    = 0x28
    case VK_ANSI_Semicolon            = 0x29
    case VK_ANSI_Backslash            = 0x2A
    case VK_ANSI_Comma                = 0x2B
    case VK_ANSI_Slash                = 0x2C
    case VK_ANSI_N                    = 0x2D
    case VK_ANSI_M                    = 0x2E
    case VK_ANSI_Period               = 0x2F
    case VK_ANSI_Grave                = 0x32
    case VK_ANSI_KeypadDecimal        = 0x41
    case VK_ANSI_KeypadMultiply       = 0x43
    case VK_ANSI_KeypadPlus           = 0x45
    case VK_ANSI_KeypadClear          = 0x47
    case VK_ANSI_KeypadDivide         = 0x4B
    case VK_ANSI_KeypadEnter          = 0x4C
    case VK_ANSI_KeypadMinus          = 0x4E
    case VK_ANSI_KeypadEquals         = 0x51
    case VK_ANSI_Keypad0              = 0x52
    case VK_ANSI_Keypad1              = 0x53
    case VK_ANSI_Keypad2              = 0x54
    case VK_ANSI_Keypad3              = 0x55
    case VK_ANSI_Keypad4              = 0x56
    case VK_ANSI_Keypad5              = 0x57
    case VK_ANSI_Keypad6              = 0x58
    case VK_ANSI_Keypad7              = 0x59
    case VK_ANSI_Keypad8              = 0x5B
    case VK_ANSI_Keypad9              = 0x5C
}

/* keycodes for keys that are independent of keyboard layout*/
enum FunctionKeys: UInt16 {
    case VK_Return                    = 0x24
    case VK_Tab                       = 0x30
    case VK_Space                     = 0x31
    case VK_Delete                    = 0x33
    case VK_Escape                    = 0x35
    case VK_Command                   = 0x37
    case VK_Shift                     = 0x38
    case VK_CapsLock                  = 0x39
    case VK_Option                    = 0x3A
    case VK_Control                   = 0x3B
    case VK_RightShift                = 0x3C
    case VK_RightOption               = 0x3D
    case VK_RightControl              = 0x3E
    case VK_Function                  = 0x3F
    case VK_F17                       = 0x40
    case VK_VolumeUp                  = 0x48
    case VK_VolumeDown                = 0x49
    case VK_Mute                      = 0x4A
    case VK_F18                       = 0x4F
    case VK_F19                       = 0x50
    case VK_F20                       = 0x5A
    case VK_F5                        = 0x60
    case VK_F6                        = 0x61
    case VK_F7                        = 0x62
    case VK_F3                        = 0x63
    case VK_F8                        = 0x64
    case VK_F9                        = 0x65
    case VK_F11                       = 0x67
    case VK_F13                       = 0x69
    case VK_F16                       = 0x6A
    case VK_F14                       = 0x6B
    case VK_F10                       = 0x6D
    case VK_F12                       = 0x6F
    case VK_F15                       = 0x71
    case VK_Help                      = 0x72
    case VK_Home                      = 0x73
    case VK_PageUp                    = 0x74
    case VK_ForwardDelete             = 0x75
    case VK_F4                        = 0x76
    case VK_End                       = 0x77
    case VK_F2                        = 0x78
    case VK_PageDown                  = 0x79
    case VK_F1                        = 0x7A
    case VK_LeftArrow                 = 0x7B
    case VK_RightArrow                = 0x7C
    case VK_DownArrow                 = 0x7D
    case VK_UpArrow                   = 0x7E
}


