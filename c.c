#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>

#pragma pack(push, 1)
typedef struct png_IHDR {
	uint32_t width; // : u32,
	uint32_t height; // : u32,
	uint8_t bit_depth; // : u8,
	uint8_t color_type;// : u8,
	uint8_t compression_method;// : u8,
	uint8_t filter_method;// : u8,
	uint8_t interlace_method;// : u8,
} png_IHDR;
#pragma pack(pop)

#pragma pack(push, 1)
typedef struct png_CHUNK_IHDR {
	uint32_t length;// : u32,
		uint32_t chunk_type;// : u32,
		png_IHDR data;// : png_IHDR,
		uint32_t crc;// : u32,
} png_CHUNK_IHDR;
#pragma pack(pop)

void SwapBytes(void* pv, size_t n)
{
	assert(n > 0);

	char* p = pv;
	size_t lo, hi;
	for (lo = 0, hi = n - 1; hi > lo; lo++, hi--)
	{
		char tmp = p[lo];
		p[lo] = p[hi];
		p[hi] = tmp;
	}
}
#define SWAP(x) SwapBytes(&x, sizeof(x));

int main(int argc, char * argv[])
{
	FILE* png = NULL;
	uint8_t* buffer = malloc(1024);

	errno_t err = fopen_s(&png, "apple.png", "rb");
	if (err || png == NULL) {
		printf("error: %d", err);
		goto cleanup;
	}

	assert(strlen(buffer) > 1024);

	fread_s(buffer, 1024, 1, 1024, png);

	const uint8_t PNG_MAGIC[] = { 137, 80, 78, 71, 13, 10, 26, 10 };

	png_CHUNK_IHDR pngChunk;
	
	int cmp = memcmp(buffer, PNG_MAGIC, 8);

	if (!cmp) {
		errno_t err = memcpy_s(&pngChunk, sizeof(pngChunk), buffer + 8, sizeof(pngChunk));
		if (err) {
			printf("memcpy_s error: %d", err);
			goto cleanup;
		}

		printf("type %x\n", pngChunk.chunk_type);

		SWAP(pngChunk.length);
		SWAP(pngChunk.data.width);
		SWAP(pngChunk.data.height);


		printf("type %x", pngChunk.chunk_type);
	}


cleanup:
	free(buffer);
	fclose(png);
	return 0;
}