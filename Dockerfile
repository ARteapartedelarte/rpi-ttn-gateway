FROM resin/rpi-raspbian

RUN apt-get update && apt-get install git iproute2 swig libftdi-dev python-dev build-essential iputils-ping WiringPi
RUN git clone -b spi https://github.com/ttn-zh/ic880a-gateway.git ~/ic880a-gateway
#RUN cd ~/ic880a-gateway && ./install.sh spi
WORKDIR /opt/ttn-gateway
RUN git clone https://github.com/devttys0/libmpsse.git
WORKDIR /opt/ttn-gateway/libmpsse/src
RUN ./configure --disable-python
RUN make
RUN make install
RUN ldconfig
WORKDIR /opt/ttn-gateway
RUN git clone https://github.com/TheThingsNetwork/lora_gateway.git
WORKDIR /opt/ttn-gateway/lora_gateway
RUN cp ./libloragw/99-libftdi.rules /etc/udev/rules.d/99-libftdi.rules

#RUN sed -i -e 's/CFG_SPI= native/CFG_SPI= ftdi/g' ./libloragw/library.cfg
RUN sed -i -e 's/PLATFORM= kerlink/PLATFORM= imst_rpi/g' ./libloragw/library.cfg
#RUN sed -i -e 's/ATTRS{idProduct}=="6010"/ATTRS{idProduct}=="6014"/g' /etc/udev/rules.d/99-libftdi.rules
#RUN sed -i -e 's/cs_change = 1/cs_change = 0/g' ./libloragw/src/loragw_spi.native.c
RUN make
WORKDIR /opt/ttn-gateway
RUN git clone https://github.com/TheThingsNetwork/packet_forwarder.git
WORKDIR /opt/ttn-gateway/packet_forwarder 
RUN make
WORKDIR /opt/ttn-gateway
RUN mkdir /opt/ttn-gateway/bin
RUN ln -s /opt/ttn-gateway/packet_forwarder/poly_pkt_fwd/poly_pkt_fwd ./bin/poly_pkt_fwd
RUN cp -f /opt/ttn-gateway/packet_forwarder/poly_pkt_fwd/global_conf.json ./bin/global_conf.json

ENV GATEWAY_EUI B827EBFFFE906B07
ENV GATEWAY_LAT 47.8
ENV GATEWAY_LON 8.1
ENV GATEWAY_ALT 400
ENV GATEWAY_EMAIL daniel.eichhorn@netcetera.com 
ENV GATEWAY_NAME NCA_ZH_1
RUN echo "{\n\t\"gateway_conf\": {\n\t\t\"gateway_ID\": \"${GATEWAY_EUI}\",\n\t\t\"servers\": [ { \"server_address\": \"router.eu.thethings.network\", \"serv_port_up\": 1700, \"serv_port_down\": 1700, \"serv_enabled\": true } ], \n\t\t\"ref_latitude\": ${GATEWAY_LAT},\n\t\t\"ref_longitude\": ${GATEWAY_LON},\n\t\t\"ref_altitude\": ${GATEWAY_ALT},\n\t\t\"contact_email\": \"${GATEWAY_EMAIL}\",\n\t\t\"description\": \"${GATEWAY_NAME}\"  \n\t}\n}" > /opt/ttn-gateway/bin/local_conf.json
RUN cat /opt/ttn-gateway/bin/local_conf.json
RUN cp ~/ic880a-gateway/start.sh /opt/ttn-gateway/bin/
RUN sed -i -e 's/SX1301_RESET_BCM_PIN=25/SX1301_RESET_BCM_PIN=17/g' /opt/ttn-gateway/bin/start.sh
RUN cp ~/ic880a-gateway/ttn-gateway.service /lib/systemd/system/
RUN systemctl enable ttn-gateway.service
