package edu.udel.eleg454.TestFactual;

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import com.factual.Factual;
import com.factual.Query;
import com.factual.ReadResponse;

import android.os.Bundle;
import android.app.Activity;
import android.util.Log;
import android.view.Menu;

public class TestFactualActivity extends Activity {								// TestFactualActivity is inherited from Activity class

	@Override
	protected void onCreate(Bundle savedInstanceState){							// Call of onCreate for first use and static set ups
		super.onCreate(savedInstanceState);										// Calling parent onCreate class
		setContentView(R.layout.activity_test_factual);
		//getFactualData();
		new Thread(new Runnable() {												// We have to use new thread each time for each latitude longitude pairs
			public void run() {

				FileReader fr;													// To read file generated from Parser.pl
				double latitude;
				double longitude;
				try {
					fr = new FileReader("/storage/sdcard0/Bluetooth/result.txt");// Accessing the file store din android device.
					BufferedReader br= new BufferedReader(fr);					
					String str;
					while((str=br.readLine())!=null)
					{
						System.out.println(str); 		 
						latitude =  Double.parseDouble(str.substring(0,9));		 // Extracting latitude value from each line in result file.
						longitude = Double.parseDouble(str.substring(10));		 // Extracting latitude value from each line in result file.
						//new Thread(new Runnable() {							 // This is the original code which will not work for multiple latitude longitude pairs
						//public void run() {
						getFactualData(latitude, longitude);					 // Call to getFactual to get the physical location store at that pair
						//}}).start();
					}
				} catch (IOException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();										 // It prints what and where the error occured
				}
			}}).start();

	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		// Inflate the menu; this adds items to the action bar if it is present.
		getMenuInflater().inflate(R.menu.test_factual, menu);
		return true;
	}

	public void getFactualData(Double latitude, Double longitude) {					
		Log.e("factual","starting");
		Factual factual = new Factual("9uEYTRbG1gizXlePqU3ZqM3cJqQUADoADiJQxii1", "vgagHeXbsnQ05rCyCYBCrWyTr3VeCGZW095LE6xc");// Credentials to login in factual database
		Query query = new Query().within(new com.factual.Circle(latitude, longitude, 5000)).limit(50).sortAsc("name"); // This will pick up all the location names near specified latitude and longitude values within 5000 meters, 50 such locations are retrieved with ascending order of names
		// gets up to 10 items that are in the 5000m circle around the lat-long point 34.06018, -118.41835. and these are sorted by name
		Log.e("factual","made query. Now fetching");
		ReadResponse readResponse = factual.fetch("places", query);					// Method to read the response from data returned by factual database
		showResponse(readResponse); // need to make this function					// Used to print the formatted output

	}

	public void showResponse(ReadResponse readResponse) {
		List<Map<String,Object>> data = readResponse.getData();						// Create the list of maps from the data received from response
		System.out.println("num items: "+data.size());
		for(Map<String,Object> item : data) {										// Print whatever is required.
			System.out.println("************new item***************");
			// see http://developer.factual.com/display/docs/Places+API+-+Global+Place+Attributes for schema
			Double latitude = (Double)item.get("latitude");         
			if (latitude==null)
				System.out.println("latitude does not exist");
			else
				System.out.println("latitude: "+latitude);
			Double longitude = (Double)item.get("longitude");         
			if (longitude==null)
				System.out.println("longitude does not exist");
			else
				System.out.println("longitude: "+longitude);
			String name = (String)item.get("name");
			if (name==null)
				System.out.println("name does not exist");
			else
				System.out.println("name: "+name);     

		}

	}
}