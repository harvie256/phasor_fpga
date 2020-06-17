/*
 * AD7779.c
 *
 *  Created on: Jun 1, 2020
 *      Author: derryn
 */

#include "main.h"


#define GENERAL_USER_CONFIG_1 0x011
#define GENERAL_USER_CONFIG_2 0x012
#define GENERAL_USER_CONFIG_3 0x013
#define DOUT_FORMAT 0x014
#define ADC_MUX_CONFIG 0x015

SPI_HandleTypeDef *hspi;

  uint8_t spi_output_buffer[32];
  uint8_t spi_input_buffer[32];


  void AD7779_software_reset(void){
  	  HAL_GPIO_WritePin(SPI2_NCS_GPIO_Port, SPI2_NCS_Pin, RESET);
  	  	 for(int i = 0; i<32; i++){
  	  		 spi_output_buffer[i] = 0xFF;
  	  	 }
  	  HAL_SPI_Transmit(hspi, spi_output_buffer, 32, 5);
  	  HAL_GPIO_WritePin(SPI2_NCS_GPIO_Port, SPI2_NCS_Pin, SET);
  }


  void AD7779_write_register(uint8_t reg_address, uint8_t data){


	  uint8_t address = reg_address & ~(1 << 7); // Clear the R/nW bit

  	  HAL_GPIO_WritePin(SPI2_NCS_GPIO_Port, SPI2_NCS_Pin, RESET);
  	  HAL_SPI_Transmit(hspi, &address, 1, 5);
  	  HAL_SPI_Transmit(hspi, &data, 1, 5);
  	  HAL_GPIO_WritePin(SPI2_NCS_GPIO_Port, SPI2_NCS_Pin, SET);

  }

  uint8_t AD7779_read_register(uint8_t reg_address){


	  uint8_t address = reg_address | (1 << 7); // Set the read bit

  	  HAL_GPIO_WritePin(SPI2_NCS_GPIO_Port, SPI2_NCS_Pin, RESET);
  	  HAL_SPI_Transmit(hspi, &address, 1, 5);
  	  HAL_SPI_Receive(hspi, spi_input_buffer, 1, 5);
  	  HAL_GPIO_WritePin(SPI2_NCS_GPIO_Port, SPI2_NCS_Pin, SET);

  	  return spi_input_buffer[0];
  }

  void AD7779_init(SPI_HandleTypeDef *spi_handle){
	  hspi = spi_handle;
	  AD7779_software_reset();
	  HAL_Delay(100);

	  AD7779_write_register(GENERAL_USER_CONFIG_1, 0x64); // Enable high res mode
	  AD7779_write_register(ADC_MUX_CONFIG, 0x40); // Set to internal reference

  }

