/*
 * Copyright (c) 2022 Villu Ruusmann
 *
 * This file is part of R2PMML
 *
 * R2PMML is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * R2PMML is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with R2PMML.  If not, see <http://www.gnu.org/licenses/>.
 */
package com.r2pmml;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;

import com.beust.jcommander.JCommander;
import com.beust.jcommander.Parameter;
import org.dmg.pmml.PMML;
import org.jpmml.model.metro.MetroJAXBUtil;
import org.jpmml.rexp.Converter;
import org.jpmml.rexp.ConverterFactory;
import org.jpmml.rexp.RExp;
import org.jpmml.rexp.RExpParser;

public class Main {

	@Parameter (
		names = "--converter",
		description = "Converter class"
	)
	private String converter = null;

	@Parameter (
		names = {"--model-rds-input", "--rds-input"},
		required = true
	)
	private File inputFile = null;

	@Parameter (
		names = {"--pmml-output"},
		required = true
	)
	private File outputFile = null;


	static
	public void main(String... args) throws Exception {
		Main main = new Main();

		JCommander commander = JCommander.newBuilder()
			.addObject(main)
			.build();

		commander.parse(args);

		main.run();
	}

	public void run() throws Exception {
		RExp rexp;

		try(InputStream is = new FileInputStream(this.inputFile)){
			RExpParser parser = new RExpParser(is);

			rexp = parser.parse();
		}

		ConverterFactory converterFactory = ConverterFactory.newInstance();

		Converter<RExp> converter;

		if(this.converter != null){
			Class<? extends Converter<?>> clazz = (Class<? extends Converter<?>>)Class.forName(this.converter);

			converter = converterFactory.newConverter(clazz, rexp);
		} else

		{
			converter = converterFactory.newConverter(rexp);
		}

		PMML pmml = converter.encodePMML();

		if(!this.outputFile.exists()){
			File absoluteOutputFile = this.outputFile.getAbsoluteFile();

			File outputDir = absoluteOutputFile.getParentFile();
			if(!outputDir.exists()){
				outputDir.mkdirs();
			}
		}

		try(OutputStream os = new FileOutputStream(this.outputFile)){
			MetroJAXBUtil.marshalPMML(pmml, os);
		}
	}
}