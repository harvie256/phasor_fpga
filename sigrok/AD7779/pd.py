##
## This file is part of the libsigrokdecode project.
##
## Copyright (C) 2017 Gerhard Sittig <gerhard.sittig@gmx.net>
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, see <http://www.gnu.org/licenses/>.
##


import sigrokdecode as srd

class Decoder(srd.Decoder):
    api_version = 3
    id = 'AD7779'
    name = "AD7779"
    longname = "AD7779 ADC Data Lanes"
    desc = '4 Lane data bus for the AD7779 ADC.'
    license = 'gplv2+'
    inputs = ['logic']
    outputs = []
    tags = ['Embedded/industrial', 'PC']
    channels = (
        {'id': 'clk', 'name': 'BIT_CLK', 'desc': 'Data bits clock'},
        {'id': 'drdy', 'name': 'DRDY', 'desc': 'Data Ready'},
        {'id': 'd0', 'name': 'D0', 'desc': 'Data lane 0'},
        {'id': 'd1', 'name': 'D1', 'desc': 'Data lane 1'},
        {'id': 'd2', 'name': 'D2', 'desc': 'Data lane 2'},
        {'id': 'd3', 'name': 'D3', 'desc': 'Data lane 3'},

    )
    optional_channels = (
    )
    annotations = (
        ('ch0_alert', 'Channel 0 Alert'),
        ('ch0_ch_num', 'Channel 0 Channel Number'),
        ('ch0_crc', 'Channel 0 CRC'),
        ('ch0_data', 'Channel 0'),
        ('ch0_conv', 'Channel 0 Conversion Result'),

    )
    annotation_rows = (
        ('CH0', 'ADC Channel 0', (0,1,2,3)),
        ('CH0_conv', 'CH0 Conversion Result', (4,)),
    )

    def __init__(self):
        print('init')

    def reset(self):
        print('reset')
        

    def start(self):
        self.out_ann = self.register(srd.OUTPUT_ANN)

    # Function from https://stackoverflow.com/questions/32030412/twos-complement-sign-extension-python
    # Used to convert the 24b 2's complement ADC result
    def sign_extend(self, value, bits):
        sign_bit = 1 << (bits - 1)
        return (value & (sign_bit - 1)) - (value & sign_bit)


    def decode(self):
        while True:
            # Wait for the DRDY pin to pulse
            self.wait({1:'r'})
            self.wait({1:'f'})
                        
            for i in range(0, 32):               
                pins = self.wait({0:'f'}) # DCLK falling edge
                
                # Channel alert bit
                if i == 0:
                    self.alert_bits = pins[2]
                    self.alert_start_sample = self.samplenum
                
                # First channel number bit
                elif i == 1:
                    self.chan_num = pins[2]
                    self.chan_num_start_sample = self.samplenum
                    
                    # Put the alert bits on the screen
                    self.put(self.alert_start_sample, self.samplenum, self.out_ann, [0, ['Alert: {}'.format(self.alert_bits),'{}'.format(self.alert_bits)]])
                    
                elif 2 <= i <= 3:
                    self.chan_num = (self.chan_num << 1) | pins[2];
                    
                # First bit of the CRC section
                elif i == 4:
                    self.crc = pins[2]
                    self.crc_start_sample = self.samplenum
                    
                    # Put the chan num on the screen
                    self.put(self.chan_num_start_sample, self.samplenum, self.out_ann, [1, ['CH #: {}'.format(self.chan_num),'{}'.format(self.chan_num)]])
                    
                elif 5 <= i <= 7:
                    self.crc = (self.crc << 1) | pins[2];
                
                # First bit of the ADC result 24b word
                elif i == 8:
                    self.data_word = pins[2]
                    self.data_word_start_sample = self.samplenum
                    
                    # Put the crc on the screen
                    self.put(self.crc_start_sample, self.samplenum, self.out_ann, [2, ['CRC: {0:X}'.format(self.crc),'{0:X}'.format(self.crc)]])
                    
                elif 9 <= i <= 31:
                    self.data_word = (self.data_word << 1) | pins[2];

            
            # finish the dataword output on the rising edge as it will look nicer
            self.wait({0:'r'}) # DCLK rising edge
            self.put(self.data_word_start_sample, self.samplenum, self.out_ann, [3, ['Conv: {0:X}'.format(self.data_word),'{0:X}'.format(self.data_word)]])
            self.put(self.data_word_start_sample, self.samplenum, self.out_ann, [4, ['{}'.format(self.sign_extend(self.data_word, 24))]])

            



