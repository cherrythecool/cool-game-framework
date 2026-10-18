#include "cherryaudio.h"

#ifdef __cplusplus
extern "C" {
#endif

#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#define DR_WAV_IMPLEMENTATION
#include "dr_wav.h"
#define DR_FLAC_IMPLEMENTATION
#include "dr_flac.h"
#define DR_MP3_FLOAT_OUTPUT
#define DR_MP3_IMPLEMENTATION
#include "dr_mp3.h"
#include <opusfile.h>

#include "stb_vorbis.c"

/* Internal use functions that get their source at the end of the file */
char *_cherry_str_pathext(const char *path);
cherry_file_format _cherry_format_from_path(const char *path);
int _cherry_vorbis_decode_file_f32(const char *filename, int *channels, int *sample_rate, float **output);
int _cherry_vorbis_decode_memory_f32(const unsigned char *mem, int len, int *channels, int *sample_rate, float **output);

cherry_file cherry_load_file(const char *path, cherry_file_format file_format, cherry_pcm_format requested_pcm_format) {
    cherry_file file = (cherry_file){0};
    switch (file_format) {
        case DETECT:
            cherry_file_format detected_format = _cherry_format_from_path(path);
            if (detected_format == DETECT) {
                return file;
            }

            return cherry_load_file(path, detected_format, requested_pcm_format);
            break;
        case WAV:
            switch (requested_pcm_format) {
                case FLOAT_32:
                    file.pcm.data = drwav_open_file_and_read_pcm_frames_f32(path, &file.meta.channels, &file.meta.sample_rate, &file.meta.sample_count, NULL);
                    file.pcm.size = file.meta.sample_count * file.meta.channels * sizeof(float);
                    break;
                case INT_16:
                    file.pcm.data = drwav_open_file_and_read_pcm_frames_s16(path, &file.meta.channels, &file.meta.sample_rate, &file.meta.sample_count, NULL);
                    file.pcm.size = file.meta.sample_count * file.meta.channels * sizeof(short);
                    break;
            }

            file.pcm.format = requested_pcm_format;
            break;
        case FLAC:
            switch (requested_pcm_format) {
                case FLOAT_32:
                    file.pcm.data = drflac_open_file_and_read_pcm_frames_f32(path, &file.meta.channels, &file.meta.sample_rate, &file.meta.sample_count, NULL);
                    file.pcm.size = file.meta.sample_count * file.meta.channels * sizeof(float);
                    break;
                case INT_16:
                    file.pcm.data = drflac_open_file_and_read_pcm_frames_s16(path, &file.meta.channels, &file.meta.sample_rate, &file.meta.sample_count, NULL);
                    file.pcm.size = file.meta.sample_count * file.meta.channels * sizeof(short);
                    break;
            }

            file.pcm.format = requested_pcm_format;
            break;
        case MP3:
            drmp3_config config;
            switch (requested_pcm_format) {
                case FLOAT_32:
                    file.pcm.data = drmp3_open_file_and_read_pcm_frames_f32(path, &config, &file.meta.sample_count, NULL);
                    file.meta.channels = config.channels;
                    file.meta.sample_rate = config.sampleRate;
                    file.pcm.size = file.meta.sample_count * file.meta.channels * sizeof(float);
                    break;
                case INT_16:
                    file.pcm.data = drmp3_open_file_and_read_pcm_frames_s16(path, &config, &file.meta.sample_count, NULL);
                    file.meta.channels = config.channels;
                    file.meta.sample_rate = config.sampleRate;
                    file.pcm.size = file.meta.sample_count * file.meta.channels * sizeof(short);
                    break;
            }

            file.pcm.format = requested_pcm_format;
            break;
        case VORBIS:
            switch (requested_pcm_format) {
                case FLOAT_32:
                    file.meta.sample_count = _cherry_vorbis_decode_file_f32(path, &file.meta.channels, &file.meta.sample_rate, (float**)&file.pcm.data);
                    file.pcm.size = file.meta.sample_count * file.meta.channels * sizeof(float);
                    break;
                case INT_16:
                    file.meta.sample_count = stb_vorbis_decode_filename(path, &file.meta.channels, &file.meta.sample_rate, (short**)&file.pcm.data);
                    file.pcm.size = file.meta.sample_count * file.meta.channels * sizeof(short);
                    break;
            }

            file.pcm.format = requested_pcm_format;
            break;
        case OPUS:
            OggOpusFile *opus = op_open_file(path, NULL);
            file.meta.channels = op_channel_count(opus, -1);
            file.meta.sample_rate = 48000;
            file.meta.sample_count = op_pcm_total(opus, -1);

            switch (requested_pcm_format) {
                case FLOAT_32: {
                    cherry_size file_size = file.meta.sample_count * file.meta.channels;
                    file.pcm.data = malloc(file_size * sizeof(float));

                    cherry_size frames = 0;
                    float *buf = file.pcm.data;
                    while (frames < file.meta.sample_count) {
                        cherry_size frame_offset = frames * file.meta.channels;
                        frames += op_read_float(opus, buf + frame_offset, file_size - frame_offset, NULL);
                    }

                    file.pcm.size = file_size * sizeof(float);
                    break;
                } case INT_16: {
                    cherry_size file_size = file.meta.sample_count * file.meta.channels;
                    file.pcm.data = malloc(file_size * sizeof(short));

                    cherry_size frames = 0;
                    short *buf = file.pcm.data;
                    while (frames < file.meta.sample_count) {
                        cherry_size frame_offset = frames * file.meta.channels;
                        frames += op_read(opus, buf + frame_offset, file_size - frame_offset, NULL);
                    }

                    file.pcm.size = file_size * sizeof(short);
                    break;
                }
            }

            file.pcm.format = requested_pcm_format;
            op_free(opus);
            break;
    }

    return file;
}

cherry_file cherry_load_file_from_memory(void *memory, cherry_size size, cherry_file_format file_format, cherry_pcm_format requested_pcm_format) {
    cherry_file file = (cherry_file){0};
    switch (file_format) {
        case DETECT:
            break;
        case WAV:
            switch (requested_pcm_format) {
                case FLOAT_32:
                    file.pcm.data = drwav_open_memory_and_read_pcm_frames_f32(memory, size,
                            &file.meta.channels, &file.meta.sample_rate, &file.meta.sample_count, NULL);
                    file.pcm.size = file.meta.sample_count * file.meta.channels * sizeof(float);
                    break;
                case INT_16:
                    file.pcm.data = drwav_open_memory_and_read_pcm_frames_s16(memory, size,
                            &file.meta.channels, &file.meta.sample_rate, &file.meta.sample_count, NULL);
                    file.pcm.size = file.meta.sample_count * file.meta.channels * sizeof(short);
                    break;
            }

            file.pcm.format = requested_pcm_format;
            break;
        case FLAC:
            switch (requested_pcm_format) {
                case FLOAT_32:
                    file.pcm.data = drflac_open_memory_and_read_pcm_frames_f32(memory, size,
                            &file.meta.channels, &file.meta.sample_rate, &file.meta.sample_count, NULL);
                    file.pcm.size = file.meta.sample_count * file.meta.channels * sizeof(float);
                    break;
                case INT_16:
                    file.pcm.data = drflac_open_memory_and_read_pcm_frames_s16(memory, size,
                            &file.meta.channels, &file.meta.sample_rate, &file.meta.sample_count, NULL);
                    file.pcm.size = file.meta.sample_count * file.meta.channels * sizeof(short);
                    break;
            }

            file.pcm.format = requested_pcm_format;
            break;
        case MP3:
            drmp3_config config;
            switch (requested_pcm_format) {
                case FLOAT_32:
                    file.pcm.data = drmp3_open_memory_and_read_pcm_frames_f32(memory, size, &config, &file.meta.sample_count, NULL);
                    file.meta.channels = config.channels;
                    file.meta.sample_rate = config.sampleRate;
                    file.pcm.size = file.meta.sample_count * file.meta.channels * sizeof(float);
                    break;
                case INT_16:
                    file.pcm.data = drmp3_open_memory_and_read_pcm_frames_s16(memory, size, &config, &file.meta.sample_count, NULL);
                    file.meta.channels = config.channels;
                    file.meta.sample_rate = config.sampleRate;
                    file.pcm.size = file.meta.sample_count * file.meta.channels * sizeof(short);
                    break;
            }

            file.pcm.format = requested_pcm_format;
            break;
        case VORBIS:
            switch (requested_pcm_format) {
                case FLOAT_32:
                    file.meta.sample_count = _cherry_vorbis_decode_memory_f32(memory, size, &file.meta.channels, &file.meta.sample_rate, (float**)&file.pcm.data);
                    file.pcm.size = file.meta.sample_count * file.meta.channels * sizeof(float);
                    break;
                case INT_16:
                    file.meta.sample_count = stb_vorbis_decode_memory(memory, size, &file.meta.channels, &file.meta.sample_rate, (short**)&file.pcm.data);
                    file.pcm.size = file.meta.sample_count * file.meta.channels * sizeof(short);
                    break;
            }

            file.pcm.format = requested_pcm_format;
            break;
        case OPUS:
            OggOpusFile *opus = op_open_memory(memory, size, NULL);
            file.meta.channels = op_channel_count(opus, -1);
            file.meta.sample_rate = 48000;
            file.meta.sample_count = op_pcm_total(opus, -1);

            switch (requested_pcm_format) {
                case FLOAT_32: {
                    cherry_size file_size = file.meta.sample_count * file.meta.channels;
                    file.pcm.data = malloc(file_size * sizeof(float));

                    cherry_size frames = 0;
                    float *buf = file.pcm.data;
                    while (frames < file.meta.sample_count) {
                        cherry_size frame_offset = frames * file.meta.channels;
                        frames += op_read_float(opus, buf + frame_offset, file_size - frame_offset, NULL);
                    }

                    file.pcm.size = file_size * sizeof(float);
                    break;
                } case INT_16: {
                    cherry_size file_size = file.meta.sample_count * file.meta.channels;
                    file.pcm.data = malloc(file_size * sizeof(short));

                    cherry_size frames = 0;
                    short *buf = file.pcm.data;
                    while (frames < file.meta.sample_count) {
                        cherry_size frame_offset = frames * file.meta.channels;
                        frames += op_read(opus, buf + frame_offset, file_size - frame_offset, NULL);
                    }

                    file.pcm.size = file_size * sizeof(short);
                    break;
                }
            }

            file.pcm.format = requested_pcm_format;
            op_free(opus);
            break;
    }

    return file;
}

cherry_stream cherry_stream_file(const char *path, cherry_file_format file_format) {
    cherry_stream stream = (cherry_stream){0};
    switch (file_format) {
        case DETECT:
            cherry_file_format detected_format = _cherry_format_from_path(path);
            if (detected_format == DETECT) {
                return stream;
            }

            return cherry_stream_file(path, detected_format);
            break;
        case WAV:
            stream.file_format = file_format;
            stream.data = malloc(sizeof(drwav));
            drwav_init_file(stream.data, path, NULL);
            stream.meta.channels = ((drwav*)stream.data)->channels;
            stream.meta.sample_rate = ((drwav*)stream.data)->sampleRate;
            stream.meta.sample_count = ((drwav*)stream.data)->totalPCMFrameCount;
            break;
        case FLAC:
            stream.file_format = file_format;
            stream.data = drflac_open_file(path, NULL);
            stream.meta.channels = ((drflac*)stream.data)->channels;
            stream.meta.sample_rate = ((drflac*)stream.data)->sampleRate;
            stream.meta.sample_count = ((drflac*)stream.data)->totalPCMFrameCount;
            break;
        case MP3:
            stream.file_format = file_format;
            stream.data = malloc(sizeof(drmp3));
            drmp3_init_file(stream.data, path, NULL);
            stream.meta.channels = ((drmp3*)stream.data)->channels;
            stream.meta.sample_rate = ((drmp3*)stream.data)->sampleRate;
            stream.meta.sample_count = drmp3_get_pcm_frame_count(stream.data);
            break;
        case VORBIS:
            stream.file_format = file_format;
            stream.data = stb_vorbis_open_filename(path, NULL, NULL);
            stb_vorbis_info info = stb_vorbis_get_info(stream.data);
            stream.meta.channels = info.channels;
            stream.meta.sample_rate = info.sample_rate;
            stream.meta.sample_count = stb_vorbis_stream_length_in_samples(stream.data);
            break;
        case OPUS:
            stream.file_format = file_format;
            stream.data = op_open_file(path, NULL);
            stream.meta.channels = op_channel_count(stream.data, -1);
            stream.meta.sample_rate = 48000;
            stream.meta.sample_count = op_pcm_total(stream.data, -1);
            break;
    }

    return stream;
}

cherry_stream cherry_stream_memory(void *memory, cherry_size size, cherry_file_format file_format) {
    cherry_stream stream = (cherry_stream){0};
    stream.memory = memory;
    switch (file_format) {
        case DETECT:
            break;
        case WAV:
            stream.file_format = file_format;
            stream.data = malloc(sizeof(drwav));
            drwav_init_memory(stream.data, memory, size, NULL);
            stream.meta.channels = ((drwav*)stream.data)->channels;
            stream.meta.sample_rate = ((drwav*)stream.data)->sampleRate;
            stream.meta.sample_count = ((drwav*)stream.data)->totalPCMFrameCount;
            break;
        case FLAC:
            stream.file_format = file_format;
            stream.data = drflac_open_memory(memory, size, NULL);
            stream.meta.channels = ((drflac*)stream.data)->channels;
            stream.meta.sample_rate = ((drflac*)stream.data)->sampleRate;
            stream.meta.sample_count = ((drflac*)stream.data)->totalPCMFrameCount;
            break;
        case MP3:
            stream.file_format = file_format;
            stream.data = malloc(sizeof(drmp3));
            drmp3_init_memory(stream.data, memory, size, NULL);
            stream.meta.channels = ((drmp3*)stream.data)->channels;
            stream.meta.sample_rate = ((drmp3*)stream.data)->sampleRate;
            stream.meta.sample_count = drmp3_get_pcm_frame_count(stream.data);
            break;
        case VORBIS:
            stream.file_format = file_format;
            stream.data = stb_vorbis_open_memory(memory, size, NULL, NULL);
            stb_vorbis_info info = stb_vorbis_get_info(stream.data);
            stream.meta.channels = info.channels;
            stream.meta.sample_rate = info.sample_rate;
            stream.meta.sample_count = stb_vorbis_stream_length_in_samples(stream.data);
            break;
        case OPUS:
            stream.file_format = file_format;
            stream.data = op_open_memory(memory, size, NULL);
            stream.meta.channels = op_channel_count(stream.data, -1);
            stream.meta.sample_rate = 48000;
            stream.meta.sample_count = op_pcm_total(stream.data, -1);
            break;
    }

    return stream;
}

cherry_pcm cherry_decode_samples(cherry_stream stream, cherry_pcm_format requested_pcm_format, cherry_size sample_count) {
    cherry_pcm pcm = (cherry_pcm){0};
    switch (stream.file_format) {
        case DETECT:
            break;
        case WAV:
            pcm.format = requested_pcm_format;
            switch (requested_pcm_format) {
                case FLOAT_32: {
                    pcm.data = malloc(sizeof(float) * sample_count * stream.meta.channels);
                    drwav_uint64 frames_read = drwav_read_pcm_frames_f32(stream.data, sample_count, pcm.data);
                    pcm.size = sizeof(float) * frames_read * stream.meta.channels;
                    break;
                } case INT_16: {
                    pcm.data = malloc(sizeof(short) * sample_count * stream.meta.channels);
                    drwav_uint64 frames_read = drwav_read_pcm_frames_s16(stream.data, sample_count, pcm.data);
                    pcm.size = sizeof(short) * frames_read * stream.meta.channels;
                    break;
                }
            }
            break;
        case FLAC:
            pcm.format = requested_pcm_format;
            switch (requested_pcm_format) {
                case FLOAT_32: {
                    pcm.data = malloc(sizeof(float) * sample_count * stream.meta.channels);
                    drflac_uint64 frames_read = drflac_read_pcm_frames_f32(stream.data, sample_count, pcm.data);
                    pcm.size = sizeof(float) * frames_read * stream.meta.channels;
                    break;
                } case INT_16: {
                    pcm.data = malloc(sizeof(short) * sample_count * stream.meta.channels);
                    drflac_uint64 frames_read = drflac_read_pcm_frames_s16(stream.data, sample_count, pcm.data);
                    pcm.size = sizeof(short) * frames_read * stream.meta.channels;
                    break;
                }
            }
            break;
        case MP3:
            pcm.format = requested_pcm_format;
            switch (requested_pcm_format) {
                case FLOAT_32: {
                    pcm.data = malloc(sizeof(float) * sample_count * stream.meta.channels);
                    drmp3_uint64 frames_read = drmp3_read_pcm_frames_f32(stream.data, sample_count, pcm.data);
                    pcm.size = sizeof(float) * frames_read * stream.meta.channels;
                    break;
                } case INT_16: {
                    pcm.data = malloc(sizeof(short) * sample_count * stream.meta.channels);
                    drmp3_uint64 frames_read = drmp3_read_pcm_frames_s16(stream.data, sample_count, pcm.data);
                    pcm.size = sizeof(short) * frames_read * stream.meta.channels;
                    break;
                }
            }
            break;
        case VORBIS:
            pcm.format = requested_pcm_format;
            switch (requested_pcm_format) {
                case FLOAT_32: {
                    pcm.data = malloc(sizeof(float) * sample_count * stream.meta.channels);
                    int frame = stb_vorbis_get_samples_float_interleaved(stream.data, stream.meta.channels, pcm.data, sample_count * stream.meta.channels);
                    if (frame == 0) {
                        pcm.size = 0;
                        return pcm;
                    }

                    pcm.size = sizeof(float) * sample_count * stream.meta.channels;
                    break;
                } case INT_16: {
                    pcm.data = malloc(sizeof(short) * sample_count * stream.meta.channels);
                    int frame = stb_vorbis_get_samples_short_interleaved(stream.data, stream.meta.channels, pcm.data, sample_count * stream.meta.channels);
                    if (frame == 0) {
                        pcm.size = 0;
                        return pcm;
                    }

                    pcm.size = sizeof(short) * sample_count * stream.meta.channels;
                    break;
                }
            }
            break;
        case OPUS:
            pcm.format = requested_pcm_format;
            switch (requested_pcm_format) {
                case FLOAT_32: {
                    cherry_size file_size = sample_count * stream.meta.channels;
                    pcm.data = malloc(file_size * sizeof(float));

                    cherry_size frames = 0;
                    float *buf = pcm.data;
                    while (frames < sample_count) {
                        cherry_size frame_offset = frames * stream.meta.channels;
                        cherry_size frame = op_read_float(stream.data, buf + frame_offset, file_size - frame_offset, NULL);
                        frames += frame;
                        if (frame == 0) {
                            break;
                        }
                    }

                    pcm.size = sizeof(float) * frames * stream.meta.channels;
                    break;
                } case INT_16: {
                    cherry_size file_size = sample_count * stream.meta.channels;
                    pcm.data = malloc(file_size * sizeof(short));

                    cherry_size frames = 0;
                    short *buf = pcm.data;
                    while (frames < sample_count) {
                        cherry_size frame_offset = frames * stream.meta.channels;
                        cherry_size frame = op_read(stream.data, buf + frame_offset, file_size - frame_offset, NULL);
                        frames += frame;
                        if (frame == 0) {
                            break;
                        }
                    }

                    pcm.size = sizeof(short) * frames * stream.meta.channels;
                    break;
                }
            }
            break;
    }

    return pcm;
}

void cherry_stream_seek_to_sample(cherry_stream stream, cherry_size sample) {
    switch (stream.file_format) {
        case DETECT:
            break;
        case WAV:
            drwav_seek_to_pcm_frame(stream.data, sample);
            break;
        case FLAC:
            drflac_seek_to_pcm_frame(stream.data, sample);
            break;
        case MP3:
            drmp3_seek_to_pcm_frame(stream.data, sample);
            break;
        case VORBIS:
            stb_vorbis_seek(stream.data, sample);
            break;
        case OPUS:
            op_pcm_seek(stream.data, sample);
            break;
    }
}

void cherry_stream_close(cherry_stream stream) {
    switch (stream.file_format) {
        case DETECT:
            break;
        case WAV:
            drwav_uninit(stream.data);
            free(stream.data);
            break;
        case FLAC:
            drflac_close(stream.data);
            break;
        case MP3:
            drmp3_uninit(stream.data);
            free(stream.data);
            break;
        case VORBIS:
            stb_vorbis_close(stream.data);
            break;
        case OPUS:
            op_free(stream.data);
            break;
    }

    if (stream.memory != NULL) {
        free(stream.memory);
    }
}

#ifndef CHERRYAUDIO_ONLY_ESSENTIALS
double cherry_file_get_length(cherry_file file) {
    return (double)file.meta.sample_count / (double)file.meta.sample_rate;
}

double cherry_stream_get_length(cherry_stream stream) {
    return (double)stream.meta.sample_count / (double)stream.meta.sample_rate;
}
#endif

/* Internal Functions (not meant to be used outside of the source for this project) */

// TODO: optimize the shit out of this function for literally no reason
char *_cherry_str_pathext(const char *path) {
    size_t length = strlen(path);
    size_t last_character = 0;
    for (size_t index = 0; index < length; ++index) {
        if (path[index] == '.') {
            last_character = index;
        }
    }

    // no file extension
    if (length == last_character + 1) {
        return NULL;
    }

    length -= last_character;
    char *extension = malloc(sizeof(char) * (length + 1));
    for (size_t index = 0; index < length; ++index) {
        extension[index] = tolower(*(path + last_character + 1 + index));
    }
    extension[length - 1] = '\0';

    return extension;
}

cherry_file_format _cherry_format_from_path(const char *path) {
    cherry_file_format format = DETECT;
    char *extension = _cherry_str_pathext(path);
    if (strcmp(extension, "wav") == 0) {
        format = WAV;
    } else if (strcmp(extension, "flac") == 0) {
        format = FLAC;
    } else if (strcmp(extension, "mp3") == 0) {
        format = MP3;
    } else if (strcmp(extension, "ogg") == 0) {
        format = VORBIS;
    } else if (strcmp(extension, "opus") == 0) {
        format = OPUS;
    }
    free(extension); // from malloc in _cherry_str_pathext
    return format;
}

int _cherry_vorbis_decode_file_f32(const char *filename, int *channels, int *sample_rate, float **output) {
   int data_len, offset, total, limit, error;
   float *data;
   stb_vorbis *v = stb_vorbis_open_filename(filename, &error, NULL);
   if (v == NULL) return -1;
   limit = v->channels * 4096;
   *channels = v->channels;
   if (sample_rate)
      *sample_rate = v->sample_rate;
   offset = data_len = 0;
   total = limit;
   data = (float *) malloc(total * sizeof(*data));
   if (data == NULL) {
      stb_vorbis_close(v);
      return -2;
   }
   for (;;) {
      int n = stb_vorbis_get_samples_float_interleaved(v, v->channels, data+offset, total-offset);
      if (n == 0) break;
      data_len += n;
      offset += n * v->channels;
      if (offset + limit > total) {
         float *data2;
         total *= 2;
         data2 = (float *) realloc(data, total * sizeof(*data));
         if (data2 == NULL) {
            free(data);
            stb_vorbis_close(v);
            return -2;
         }
         data = data2;
      }
   }
   *output = data;
   stb_vorbis_close(v);
   return data_len;
}

int _cherry_vorbis_decode_memory_f32(const unsigned char *mem, int len, int *channels, int *sample_rate, float **output) {
   int data_len, offset, total, limit, error;
   float *data;
   stb_vorbis *v = stb_vorbis_open_memory(mem, len, &error, NULL);
   if (v == NULL) return -1;
   limit = v->channels * 4096;
   *channels = v->channels;
   if (sample_rate)
      *sample_rate = v->sample_rate;
   offset = data_len = 0;
   total = limit;
   data = (float *) malloc(total * sizeof(*data));
   if (data == NULL) {
      stb_vorbis_close(v);
      return -2;
   }
   for (;;) {
      int n = stb_vorbis_get_samples_float_interleaved(v, v->channels, data+offset, total-offset);
      if (n == 0) break;
      data_len += n;
      offset += n * v->channels;
      if (offset + limit > total) {
         float *data2;
         total *= 2;
         data2 = (float *) realloc(data, total * sizeof(*data));
         if (data2 == NULL) {
            free(data);
            stb_vorbis_close(v);
            return -2;
         }
         data = data2;
      }
   }
   *output = data;
   stb_vorbis_close(v);
   return data_len;
}

#ifdef __cplusplus
}
#endif // extern "C" {
