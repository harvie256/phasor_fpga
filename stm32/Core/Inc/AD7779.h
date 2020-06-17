/*
 * AD7779.h
 *
 *  Created on: Jun 1, 2020
 *      Author: derryn
 */

#ifndef INC_AD7779_H_
#define INC_AD7779_H_


void AD7779_software_reset(void);

void AD7779_init(SPI_HandleTypeDef *spi_handle);
uint8_t AD7779_read_register(uint8_t reg_address);
void AD7779_write_register(uint8_t reg_address, uint8_t data);


#endif /* INC_AD7779_H_ */
