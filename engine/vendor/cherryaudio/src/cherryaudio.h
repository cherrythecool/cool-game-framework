#ifndef CHERRYAUDIO_H
#define CHERRYAUDIO_H

#ifdef __cplusplus
extern "C" {
#endif

typedef long long unsigned int cherry_size;

typedef enum {
    FLOAT_32 = 0,
    INT_16 = 1
} cherry_pcm_format;

typedef enum {
    DETECT = 0,
    WAV = 1,
    FLAC = 2,
    MP3 = 3,
    VORBIS = 4,
    OPUS = 5
} cherry_file_format;

typedef struct {
    unsigned int channels;
    unsigned int sample_rate;
    cherry_size sample_count;
} cherry_metadata;

typedef struct {
    void *data;
    cherry_size size;
    cherry_pcm_format format;
} cherry_pcm;

typedef struct {
    cherry_pcm pcm;
    cherry_metadata meta;
} cherry_file;

typedef struct {
    // Variable used internally to track format specific identifiers
    // for streaming audio, such as a `drwav`, `drmp3`, etc.
    void *data;

    // Variable used internally to track the raw file bytes.
    // Can be used to track anything but is automatically freed when cherry_stream_close is called
    // and it's not NULL.
    void *memory;

    cherry_file_format file_format;
    cherry_metadata meta;
} cherry_stream;

/* Essential Functions */

cherry_file cherry_load_file(const char *path, cherry_file_format file_format, cherry_pcm_format requested_pcm_format);
cherry_file cherry_load_file_from_memory(void *memory, cherry_size size, cherry_file_format file_format, cherry_pcm_format requested_pcm_format);

cherry_stream cherry_stream_file(const char *path, cherry_file_format file_format);
cherry_stream cherry_stream_memory(void *memory, cherry_size size, cherry_file_format file_format);
cherry_pcm cherry_decode_samples(cherry_stream stream, cherry_pcm_format requested_pcm_format, cherry_size sample_count);
void cherry_stream_seek_to_sample(cherry_stream stream, cherry_size sample);
void cherry_stream_close(cherry_stream stream);

/* Utility / Helper Functions */

#ifndef CHERRYAUDIO_ONLY_ESSENTIALS
double cherry_file_get_length(cherry_file file);
double cherry_stream_get_length(cherry_stream stream);
#endif

#ifdef __cplusplus
}
#endif // extern "C" {

#endif // !CHERRYAUDIO_H
