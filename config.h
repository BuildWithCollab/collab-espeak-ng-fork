// 🔧 Generated config.h for espeak-ng (xmake build)
#ifdef __linux__
#define HAVE_MKSTEMP 1
#define HAVE_NBTOOL_CONFIG_H 0
#define HAVE_DECL_OPTRESET 0
#define HAVE_SYS_ENDIAN_H 0
#define HAVE_ISWBLANK 1
#elif defined(__APPLE__)
#define HAVE_MKSTEMP 1
#define HAVE_NBTOOL_CONFIG_H 0
#define HAVE_DECL_OPTRESET 1
#define HAVE_SYS_ENDIAN_H 0
#define HAVE_ISWBLANK 1
#elif defined(_WIN32)
#define HAVE_MKSTEMP 0
#define HAVE_NBTOOL_CONFIG_H 0
#define HAVE_DECL_OPTRESET 0
#define HAVE_SYS_ENDIAN_H 0
#define HAVE_ISWBLANK 0
#endif

#define USE_ASYNC 0
#define USE_KLATT 1
#define USE_LIBPCAUDIO 0
#define USE_LIBSONIC 0
#define USE_MBROLA 0
#define USE_SPEECHPLAYER 1

#define PACKAGE_VERSION "1.52.0.1"
