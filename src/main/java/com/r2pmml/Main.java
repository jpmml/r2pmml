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
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Collection;
import java.util.List;
import java.util.logging.LogManager;

import com.beust.jcommander.JCommander;
import com.beust.jcommander.Parameter;
import com.google.common.collect.LinkedHashMultiset;
import com.google.common.collect.Multiset;
import com.sun.istack.logging.Logger;
import org.dmg.pmml.PMML;
import org.dmg.pmml.Version;
import org.jpmml.converter.Application;
import org.jpmml.converter.VersionConverter;
import org.jpmml.model.JAXBSerializer;
import org.jpmml.model.MarkupException;
import org.jpmml.model.PMMLOutputStream;
import org.jpmml.model.metro.MetroJAXBSerializer;
import org.jpmml.model.visitors.VersionChecker;
import org.jpmml.model.visitors.VersionDowngrader;
import org.jpmml.model.visitors.VersionStandardizer;
import org.jpmml.rexp.Converter;
import org.jpmml.rexp.ConverterFactory;
import org.jpmml.rexp.RExp;
import org.jpmml.rexp.RExpParser;

public class Main extends Application {

	@Parameter (
		names = {"--model-rds-input", "--rds-input"},
		required = true,
		order = 1
	)
	private File inputFile = null;

	@Parameter (
		names = {"--pmml-output"},
		required = true,
		order = 2
	)
	private File outputFile = null;

	@Parameter (
		names = "--converter",
		description = "Converter class",
		order = 3
	)
	private String converter = null;

	@Parameter (
		names = {"--pmml-schema", "--schema"},
		converter = VersionConverter.class,
		order = 4
	)
	private Version version = null;


	static
	public void main(String... args) throws Exception {
		Main application = new Main();

		JCommander commander = JCommander.newBuilder()
			.addObject(application)
			.build();

		commander.parse(args);

		try {
			Application.setInstance(application);

			application.run();
		} finally {
			Application.setInstance(null);
		}
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
		} // End if

		if(this.version != null && this.version.compareTo(Version.XPMML) < 0){
			VersionStandardizer versionStandardizer = new VersionStandardizer();
			versionStandardizer.applyTo(pmml);

			VersionDowngrader versionDowngrader = new VersionDowngrader(this.version);
			versionDowngrader.applyTo(pmml);

			VersionChecker versionChecker = new VersionChecker(this.version);
			versionChecker.applyTo(pmml);

			List<MarkupException> exceptions = versionChecker.getExceptions();
			if(!exceptions.isEmpty()){
				Main.logger.severe("The PMML object has " + exceptions.size() + " incompatibilities with the requested PMML schema version:");

				Multiset<String> groupedMessages = LinkedHashMultiset.create();

				for(MarkupException exception : exceptions){
					groupedMessages.add(exception.getMessage());
				}

				Collection<Multiset.Entry<String>> entries = groupedMessages.entrySet();
				for(Multiset.Entry<String> entry : entries){
					Main.logger.warning(entry.getElement() + (entry.getCount() > 1 ? " (" + entry.getCount() + " cases)": ""));
				}
			}

			JAXBSerializer jaxbSerializer = new MetroJAXBSerializer();

			try(OutputStream os = new PMMLOutputStream(new FileOutputStream(this.outputFile), this.version)){
				jaxbSerializer.serializePretty(pmml, os);
			}
		} else

		{
			JAXBSerializer jaxbSerializer = new MetroJAXBSerializer();

			try(OutputStream os = new FileOutputStream(this.outputFile)){
				jaxbSerializer.serializePretty(pmml, os);
			}
		}
	}

	static {
		LogManager logManager = LogManager.getLogManager();

		try {
			logManager.readConfiguration(Main.class.getResourceAsStream("/logging.properties"));
		} catch(IOException ioe){
			ioe.printStackTrace(System.err);
		}
	}

	private static final Logger logger = Logger.getLogger(Main.class);
}