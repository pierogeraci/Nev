package it.softstrategy.nevis.license;

import java.util.Arrays;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;

import it.softstrategy.nevis.license.activation.ActivationRequestBuilder;

/**
 * 
 * 	Affinché l'applicazioni funzioni è necessario che venga definita dallo script
 *  che lancia l'applicazione la variabile di ambiente NEVIS_HOME come avviene per 
 *  NevisEngine e NevisMonitor
 * 
 */
public class AppMain 
{
	
    public static void main( String[] args ){
    	
        CommandLineParser parser = new DefaultParser();
    	
    	Options options = generateOptions();
    	
    	
    	try {
			CommandLine cl = parser.parse(options, args);
			
			ActivationRequestBuilder rb = new ActivationRequestBuilder();
			if (cl.hasOption("h")) {
				printHelp(options);
				System.exit(0);
			} else if (cl.hasOption("o")) {
				String f = cl.getOptionValue("o");
				if (f != null && f.length() > 0) {
					rb.setOutputFileName(f);
				}
			}
			
			//3 Generazione file di richiesta attivazione
	    	rb.generateActivationRequest();
	    	
	    	
		} catch (ParseException e) {
//			e.printStackTrace();
			
			System.err.println(           
					"ERROR: Unable to parse command-line arguments "
					+ Arrays.toString(args) + " due to: " + e);
		} catch (Exception e) {
//			e.printStackTrace();
			System.err.println("ERROR: Cannot create Activation request File due to: " + e);
		}

    	
    }
    
    private static Options generateOptions() {
    	
    	final Option helpOption = Option.builder("h")
    			.required(false)
    			.hasArg(false)
    			.longOpt("help")
    			.desc("print this help and exit")
    			.build();
    	final Option outputFileOption = Option.builder("o")
    			.required(false)
    			.hasArg(true)
    			.longOpt("outputfile")
    			.desc("output file to be produced")
    			.build();
    	
    	final Options options = new Options();
    	options.addOption(helpOption);
    	options.addOption(outputFileOption);
    	return options;
    }
    

    
    private static void printHelp(final Options options)

    {

       final HelpFormatter formatter = new HelpFormatter();
       final String syntax = "java -jar " + new java.io.File(AppMain.class.getProtectionDomain()
    		   .getCodeSource()
    		   .getLocation()
    		   .getPath())
    		 .getName();
//       final String usageHeader = "Options:";
//       final String usageFooter = "";
//       formatter.printHelp(syntax, usageHeader, options, usageFooter);
       formatter.printHelp(syntax, options);

    }
}
