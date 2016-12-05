#include <errno.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <linux/i2c-dev.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <time.h>

#define READ_RELH 0xE5
#define READ_TEMP 0xE3

#define BUFFER_LENGTH 64

void check(const int cmd_return_value, const char* description) {
    if( cmd_return_value < 0 ) {
        perror(description);
        exit(cmd_return_value);
    }
}

int16_t get_measurement(const uint8_t cmd, const int file) {
    char config[1] = {cmd};
    write(file, config, 1);
    //sleep(1);

    uint8_t data[2];
    // Read 2 bytes of data: MSB then LSB
    if(read(file, data, 2) != 2)
    {
        printf("Failed to read the right amount of bytes for command %x", cmd);
        return -1;
    }
    // concatenate bytes into a word
    return (data[0] << 8) + data[1];
}

void get_time_string(char* buffer, size_t buffer_length) {
    time_t now = time(NULL);
    struct tm* t = localtime(&now);
    strftime(buffer, buffer_length, "%m/%d/%Y %r", t);
}

int main(int argc, char** argv)
{
    char* bus = "/dev/i2c-1";
    uint8_t address = 0x40;
    int file;
    char date[BUFFER_LENGTH];

    get_time_string(date, BUFFER_LENGTH);

    // Open I2C bus
    check((file = open(bus, O_RDWR)),
          "open()");

    // Get I2C device at the given address
    check(ioctl(file, I2C_SLAVE, address),
          "ioctl()");

    int16_t data;

    // Get humidity measurement
    check((data = get_measurement(READ_RELH, file)),
          "get_measurement(READ_RELH)");

    float rel_humidity = ((data * 125.0) / 65536.0) - 6;

    // Get temperature measurement
    check((data = get_measurement(READ_TEMP, file)),
          "get_measurement(READ_TEMP)");

    float cTemp = ((data * 175.72) / 65536.0) - 46.85;
    float fTemp = cTemp * 1.8 + 32;

    printf("%s,%.2f,%.2f\n", date, fTemp, rel_humidity);

    check(close(file), "close()");
    return 0;
}
