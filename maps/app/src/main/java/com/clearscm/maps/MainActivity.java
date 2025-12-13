package com.clearscm.maps;

import android.app.Activity;
import android.os.AsyncTask;
import android.os.Bundle;
import android.text.InputType;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;
import org.json.JSONObject;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;

public class MainActivity extends Activity {

    private TextView outputView;
    private EditText usernameField;
    private EditText passwordField;
    // TODO: Update this URL to point to your actual server
    private static final String API_URL = "https://earth.defariahome.com/maps/bin/api.cgi";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(50, 50, 50, 50);

        usernameField = new EditText(this);
        usernameField.setHint("Username");
        layout.addView(usernameField);

        passwordField = new EditText(this);
        passwordField.setHint("Password");
        passwordField.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD);
        layout.addView(passwordField);

        Button loginButton = new Button(this);
        loginButton.setText("Login");
        layout.addView(loginButton);

        outputView = new TextView(this);
        outputView.setTextSize(16);
        outputView.setPadding(0, 20, 0, 0);
        layout.addView(outputView);

        setContentView(layout);

        loginButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                String user = usernameField.getText().toString();
                String pass = passwordField.getText().toString();
                outputView.setText("Logging in...");
                new MapsTask().execute(user, pass);
            }
        });
    }

    private class MapsTask extends AsyncTask<String, Void, String> {
        @Override
        protected String doInBackground(String... params) {
            try {
                String username = params[0];
                String password = params[1];

                // 1. Login
                String loginParams = "action=login&username=" + URLEncoder.encode(username, "UTF-8") +
                        "&password=" + URLEncoder.encode(password, "UTF-8");

                String loginResponse = sendRequest(API_URL, "POST", loginParams);
                JSONObject loginJson = new JSONObject(loginResponse);

                if (!"success".equals(loginJson.optString("status"))) {
                    return "Login Failed: " + loginJson.optString("message");
                }

                String userid = loginJson.getString("userid");

                // 2. Fetch Stats
                String statsUrl = API_URL + "?action=stats&userid=" + userid;
                String statsResponse = sendRequest(statsUrl, "GET", null);
                JSONObject statsJson = new JSONObject(statsResponse);

                if (!"success".equals(statsJson.optString("status"))) {
                    return "Stats Failed: " + statsJson.optString("message");
                }

                JSONObject data = statsJson.getJSONObject("data");

                return "MAPS Quick Stats for " + userid + "\n\n" +
                        "Processed: " + data.optInt("processed") + "\n" +
                        "Whitelist: " + data.optInt("whitelist") + "\n" +
                        "Blacklist: " + data.optInt("blacklist") + "\n" +
                        "Nulllist:  " + data.optInt("nulllist") + "\n" +
                        "Errors:    " + data.optInt("error");

            } catch (Exception e) {
                return "Error: " + e.getMessage();
            }
        }

        @Override
        protected void onPostExecute(String result) {
            outputView.setText(result);
        }

        private String sendRequest(String urlStr, String method, String postParams) throws Exception {
            URL url = new URL(urlStr);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod(method);

            if (postParams != null) {
                conn.setDoOutput(true);
                OutputStream os = conn.getOutputStream();
                os.write(postParams.getBytes());
                os.flush();
                os.close();
            }

            BufferedReader in = new BufferedReader(new InputStreamReader(conn.getInputStream()));
            StringBuilder response = new StringBuilder();
            String inputLine;
            while ((inputLine = in.readLine()) != null) {
                response.append(inputLine);
            }
            in.close();
            return response.toString();
        }
    }
}