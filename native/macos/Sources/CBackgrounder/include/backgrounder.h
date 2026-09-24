#ifndef BACKGROUNDER_H
#define BACKGROUNDER_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
uint32_t backgrounder_api_version(void);
void *backgrounder_create(const char *folder, const char *ffprobe);
char *backgrounder_snapshot(void *engine);
char *backgrounder_build(void *engine);
void backgrounder_refresh(void *engine);
char *backgrounder_last_error(void);
void backgrounder_free_string(char *value);
void backgrounder_destroy(void *engine);
#ifdef __cplusplus
}
#endif
#endif
