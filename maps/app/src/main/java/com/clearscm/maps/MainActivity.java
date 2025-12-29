package com.clearscm.maps;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.os.AsyncTask;
import android.content.SharedPreferences;
import android.content.Context;
import android.os.Bundle;
import android.text.InputType;
import android.text.Html;
import android.os.Build;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.Window;
import android.view.KeyEvent;
import android.view.Menu;
import android.view.MenuItem;
import android.view.ViewGroup;
import android.view.View;
import android.widget.ImageView;
import android.widget.Button;
import android.widget.Spinner;
import android.view.autofill.AutofillManager;
import android.view.inputmethod.InputMethodManager;
import android.view.inputmethod.EditorInfo;
import android.widget.ArrayAdapter;
import android.widget.FrameLayout;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.PopupMenu;
import android.widget.ProgressBar;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.TableLayout;
import android.widget.TableRow;
import android.content.Intent;
import android.net.Uri;
import android.graphics.Color;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.List;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebSettings;
import android.webkit.CookieManager;
import android.view.ViewTreeObserver;

public class MainActivity extends Activity {

    private static final String VERSION = "1.0";
    private TextView outputView;
    private LinearLayout outputContainer;
    private EditText usernameField;
    private EditText passwordField;
    private LinearLayout loginLayout;
    private LinearLayout menuLayout;
    private LinearLayout navButtonsLayout;
    private Button backButton;
    private Button menuButton;
    private boolean isLoggedIn = false;
    private static String storedCookie = null;
    private static String storedUserid = null;
    private String lastListAction = "stats";
    private ScrollView scrollView;
    private int currentOffset = 0;
    private boolean isLoading = false;
    private static final int PAGE_SIZE = 20;
    private ProgressBar loadingSpinner;
    private static final String API_URL = "https://defaria.com/maps/bin/api.cgi";
    private FrameLayout contentFrame;
    private WebView currentWebView;
    private String lastSearchQuery = "";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        requestWindowFeature(Window.FEATURE_NO_TITLE);

        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(50, 50, 50, 50);
        layout.setBackgroundColor(Color.BLACK);

        TextView mapsTitle = new TextView(this);
        String titleHtml = "<font color='#4285F4'>M</font>.<font color='#EA4335'>A</font>.<font color='#FBBC05'>P</font>.<font color='#34A853'>S</font>.";
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            mapsTitle.setText(Html.fromHtml(titleHtml, Html.FROM_HTML_MODE_LEGACY));
        } else {
            mapsTitle.setText(Html.fromHtml(titleHtml));
        }
        mapsTitle.setTextSize(48);
        mapsTitle.setTypeface(null, Typeface.BOLD);
        mapsTitle.setTextColor(Color.WHITE);
        mapsTitle.setGravity(Gravity.CENTER);
        mapsTitle.setPadding(0, 10, 0, 10);
        mapsTitle.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (isLoggedIn) {
                    performAction(usernameField.getText().toString(), passwordField.getText().toString(), "stats");
                }
            }
        });
        layout.addView(mapsTitle);

        RelativeLayout headerLayout = new RelativeLayout(this);

        View.OnClickListener homeListener = new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (isLoggedIn) {
                    performAction(usernameField.getText().toString(), passwordField.getText().toString(), "stats");
                }
            }
        };

        ImageView bannerView = new ImageView(this);
        int bannerResource = getResources().getIdentifier("mapsbanner", "drawable", getPackageName());
        if (bannerResource != 0) {
            bannerView.setImageResource(bannerResource);
            bannerView.setAdjustViewBounds(true);
            RelativeLayout.LayoutParams bannerParams = new RelativeLayout.LayoutParams(
                    RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.WRAP_CONTENT);
            bannerView.setLayoutParams(bannerParams);
            bannerView.setOnClickListener(homeListener);
            headerLayout.addView(bannerView);
        }

        layout.addView(headerLayout);

        loginLayout = new LinearLayout(this);
        loginLayout.setOrientation(LinearLayout.VERTICAL);
        loginLayout.setGravity(Gravity.CENTER_HORIZONTAL);

        TextView usernameLabel = new TextView(this);
        usernameLabel.setText("Username");
        styleLabel(usernameLabel);
        loginLayout.addView(usernameLabel);

        usernameField = new EditText(this);
        usernameField.setId(1001);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            usernameField.setAutofillHints(View.AUTOFILL_HINT_USERNAME);
            usernameField.setImportantForAutofill(View.IMPORTANT_FOR_AUTOFILL_YES);
            usernameField.setOnFocusChangeListener(new View.OnFocusChangeListener() {
                @Override
                public void onFocusChange(View v, boolean hasFocus) {
                    if (hasFocus) {
                        AutofillManager afm = getSystemService(AutofillManager.class);
                        if (afm != null)
                            afm.requestAutofill(v);
                    }
                }
            });
        }
        styleEditText(usernameField, "Enter username");
        usernameField.setInputType(InputType.TYPE_CLASS_TEXT);
        loginLayout.addView(usernameField);

        TextView passwordLabel = new TextView(this);
        passwordLabel.setText("Password");
        styleLabel(passwordLabel);
        loginLayout.addView(passwordLabel);

        passwordField = new EditText(this);
        passwordField.setId(1002);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            passwordField.setAutofillHints(View.AUTOFILL_HINT_PASSWORD);
            passwordField.setImportantForAutofill(View.IMPORTANT_FOR_AUTOFILL_YES);
        }
        styleEditText(passwordField, "Enter password");
        passwordField.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD);
        loginLayout.addView(passwordField);

        Button loginButton = new Button(this);
        loginButton.setText("Login");
        loginButton.setBackgroundColor(Color.parseColor("#00a76b"));
        loginButton.setTextColor(Color.WHITE);
        loginLayout.addView(loginButton);

        layout.addView(loginLayout);

        menuLayout = new LinearLayout(this);
        menuLayout.setOrientation(LinearLayout.HORIZONTAL);
        menuLayout.setVisibility(View.GONE);

        addMenuButton("Returned", "returned");
        addMenuButton("White", "white_today");
        addMenuButton("Black", "black_today");
        addMenuButton("Null", "null_today");

        layout.addView(menuLayout);

        navButtonsLayout = new LinearLayout(this);
        navButtonsLayout.setOrientation(LinearLayout.HORIZONTAL);
        navButtonsLayout.setVisibility(View.GONE);

        Button btnTop = new Button(this);
        btnTop.setText("Top");
        btnTop.setBackgroundColor(Color.parseColor("#073580"));
        btnTop.setTextColor(Color.WHITE);
        btnTop.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                performAction(usernameField.getText().toString(), passwordField.getText().toString(), lastListAction,
                        0);
                scrollView.fullScroll(ScrollView.FOCUS_UP);
            }
        });
        LinearLayout.LayoutParams navParams = new LinearLayout.LayoutParams(
                0, LinearLayout.LayoutParams.WRAP_CONTENT, 1.0f);
        navParams.setMargins(5, 0, 5, 0);
        btnTop.setLayoutParams(navParams);
        navButtonsLayout.addView(btnTop);

        Button btnBottom = new Button(this);
        btnBottom.setText("Bottom");
        btnBottom.setBackgroundColor(Color.parseColor("#073580"));
        btnBottom.setTextColor(Color.WHITE);
        btnBottom.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                performAction(usernameField.getText().toString(), passwordField.getText().toString(),
                        "last_page_" + lastListAction);
            }
        });
        btnBottom.setLayoutParams(navParams);
        navButtonsLayout.addView(btnBottom);

        Button btnRefresh = new Button(this);
        btnRefresh.setText("Refresh");
        btnRefresh.setBackgroundColor(Color.parseColor("#073580"));
        btnRefresh.setTextColor(Color.WHITE);
        btnRefresh.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (isLoggedIn) {
                    performAction(usernameField.getText().toString(), passwordField.getText().toString(),
                            lastListAction, currentOffset);
                }
            }
        });
        btnRefresh.setLayoutParams(navParams);
        navButtonsLayout.addView(btnRefresh);

        layout.addView(navButtonsLayout);

        contentFrame = new FrameLayout(this);
        LinearLayout.LayoutParams frameParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 0, 1.0f);
        contentFrame.setLayoutParams(frameParams);

        scrollView = new ScrollView(this);
        FrameLayout.LayoutParams scrollParams = new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT);
        scrollView.setLayoutParams(scrollParams);
        outputContainer = new LinearLayout(this);
        outputContainer.setOrientation(LinearLayout.VERTICAL);
        scrollView.addView(outputContainer);
        contentFrame.addView(scrollView);

        layout.addView(contentFrame);

        scrollView.getViewTreeObserver().addOnScrollChangedListener(new ViewTreeObserver.OnScrollChangedListener() {
            @Override
            public void onScrollChanged() {
                if (scrollView.getVisibility() != View.VISIBLE) return;
                View view = scrollView.getChildAt(0);
                if (view != null) {
                    // Trigger when within 100 pixels of the bottom
                    int diff = (view.getBottom() - (scrollView.getHeight() + scrollView.getScrollY()));
                    if (diff <= 100) {
                        if (!isLoading && isLoggedIn && !lastListAction.equals("display")
                                && !lastListAction.equals("stats")
                                && !lastListAction.equals("top20")) {
                            loadNextPage();
                        }
                    }
                }
            }
        });

        outputView = new TextView(this);
        outputView.setTextSize(16);
        outputView.setPadding(0, 20, 0, 0);
        outputView.setTextColor(Color.WHITE);
        outputView.setTextIsSelectable(true);
        outputView.setFocusable(true);
        outputView.setLongClickable(true);
        outputContainer.addView(outputView);

        RelativeLayout bottomLayout = new RelativeLayout(this);
        LinearLayout.LayoutParams bottomLayoutParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        bottomLayout.setLayoutParams(bottomLayoutParams);

        backButton = new Button(this);
        backButton.setText("Back");
        backButton.setBackgroundColor(Color.BLACK);
        backButton.setTextColor(Color.WHITE);
        backButton.setVisibility(View.GONE);
        backButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                performAction(usernameField.getText().toString(), passwordField.getText().toString(), lastListAction);
            }
        });
        RelativeLayout.LayoutParams backParams = new RelativeLayout.LayoutParams(
                RelativeLayout.LayoutParams.WRAP_CONTENT, RelativeLayout.LayoutParams.WRAP_CONTENT);
        backParams.addRule(RelativeLayout.ALIGN_PARENT_LEFT);
        backParams.addRule(RelativeLayout.CENTER_VERTICAL);
        backButton.setLayoutParams(backParams);
        bottomLayout.addView(backButton);

        menuButton = new Button(this);
        menuButton.setText("☰");
        menuButton.setTextColor(Color.WHITE);
        menuButton.setTextSize(30);
        menuButton.setBackgroundColor(Color.TRANSPARENT);
        menuButton.setPadding(0, 0, 0, 0);
        menuButton.setMinimumWidth(0);
        menuButton.setVisibility(View.GONE);
        menuButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                showPopupMenu(v);
            }
        });
        RelativeLayout.LayoutParams menuParams = new RelativeLayout.LayoutParams(
                RelativeLayout.LayoutParams.WRAP_CONTENT, RelativeLayout.LayoutParams.WRAP_CONTENT);
        menuParams.addRule(RelativeLayout.ALIGN_PARENT_RIGHT);
        menuParams.addRule(RelativeLayout.CENTER_VERTICAL);
        menuButton.setLayoutParams(menuParams);
        bottomLayout.addView(menuButton);

        layout.addView(bottomLayout);

        loadingSpinner = new ProgressBar(this);
        LinearLayout.LayoutParams spinnerParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        spinnerParams.gravity = Gravity.CENTER_HORIZONTAL;
        spinnerParams.setMargins(0, 20, 0, 20);
        loadingSpinner.setLayoutParams(spinnerParams);

        setContentView(layout);

        loginButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                InputMethodManager imm = (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
                if (imm != null) {
                    imm.hideSoftInputFromWindow(v.getWindowToken(), 0);
                }

                String user = usernameField.getText().toString();
                String pass = passwordField.getText().toString();
                performAction(user, pass, "stats");
            }
        });

        SharedPreferences prefs = getSharedPreferences("MAPSPrefs", MODE_PRIVATE);
        storedCookie = prefs.getString("cookie", null);
        storedUserid = prefs.getString("userid", null);

        if (storedCookie != null && storedUserid != null) {
            usernameField.setText(storedUserid);
            performAction(storedUserid, "", "stats");
        }
    }

    @Override
    public void onBackPressed() {
        if (currentWebView != null) {
            resetWebView();
            return;
        }
        if (isLoggedIn && !"stats".equals(lastListAction)) {
            performAction(usernameField.getText().toString(), passwordField.getText().toString(), "stats");
            return;
        }
        super.onBackPressed();
    }

    private void showPopupMenu(View v) {
        PopupMenu popup = new PopupMenu(this, v);
        popup.getMenu().add(0, 1, 0, "Quickstats");
        popup.getMenu().add(0, 10, 0, "Statistics");
        popup.getMenu().add(0, 2, 0, "Top 20");
        popup.getMenu().add(0, 3, 0, "Search");
        popup.getMenu().add(0, 4, 0, "Check Email");
        popup.getMenu().add(0, 7, 0, "White List");
        popup.getMenu().add(0, 8, 0, "Black List");
        popup.getMenu().add(0, 9, 0, "Null List");
        popup.getMenu().add(0, 5, 0, "About");
        popup.getMenu().add(0, 6, 0, "Logout");
        popup.setOnMenuItemClickListener(new PopupMenu.OnMenuItemClickListener() {
            @Override
            public boolean onMenuItemClick(MenuItem item) {
                return handleMenuItem(item);
            }
        });
        popup.show();
    }

    private boolean handleMenuItem(MenuItem item) {
        String user = usernameField.getText().toString();
        String pass = passwordField.getText().toString();
        switch (item.getItemId()) {
            case 1:
                performAction(user, pass, "stats");
                return true;
            case 2:
                performAction(user, pass, "top20");
                return true;
            case 3:
                showInputDialog("Search", "search");
                return true;
            case 4:
                showInputDialog("Check Email", "check_address");
                return true;
            case 7:
                performAction(user, pass, "white");
                return true;
            case 8:
                performAction(user, pass, "black");
                return true;
            case 9:
                performAction(user, pass, "null");
                return true;
            case 10:
                performAction(user, pass, "full_stats");
                return true;
            case 5:
                showAboutDialog();
                return true;
            case 6:
                isLoggedIn = false;
                storedCookie = null;
                storedUserid = null;

                SharedPreferences prefs = getSharedPreferences("MAPSPrefs", MODE_PRIVATE);
                SharedPreferences.Editor editor = prefs.edit();
                editor.remove("cookie");
                editor.remove("userid");
                editor.apply();

                loginLayout.setVisibility(View.VISIBLE);
                menuLayout.setVisibility(View.GONE);
                menuButton.setVisibility(View.GONE);
                outputView.setText("");
                passwordField.setText("");
                backButton.setVisibility(View.GONE);
                return true;
            default:
                return false;
        }
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        if (isLoggedIn) {
            menu.add(0, 1, 0, "Quickstats");
            menu.add(0, 10, 0, "Statistics");
            menu.add(0, 2, 0, "Top 20");
            menu.add(0, 3, 0, "Search");
            menu.add(0, 4, 0, "Check Email");
            menu.add(0, 7, 0, "White List");
            menu.add(0, 8, 0, "Black List");
            menu.add(0, 9, 0, "Null List");
            menu.add(0, 5, 0, "About");
            menu.add(0, 6, 0, "Logout");
        }
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        return handleMenuItem(item) || super.onOptionsItemSelected(item);
    }

    private void showAboutDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("About MAPS Mobile");

        ScrollView scrollView = new ScrollView(this);
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(40, 20, 40, 20);
        layout.setGravity(Gravity.CENTER_HORIZONTAL);

        ImageView logoView = new ImageView(this);
        int imageResource = getResources().getIdentifier("maps", "drawable", getPackageName());
        if (imageResource != 0) {
            logoView.setImageResource(imageResource);
        }
        logoView.setAdjustViewBounds(true);
        LinearLayout.LayoutParams logoParams = new LinearLayout.LayoutParams(1000, 1000);
        logoView.setLayoutParams(logoParams);
        layout.addView(logoView);

        TextView versionText = new TextView(this);
        versionText.setText("Version " + VERSION);
        versionText.setTextSize(22);
        versionText.setTypeface(null, Typeface.BOLD);
        versionText.setTextColor(Color.YELLOW);
        versionText.setPadding(0, 20, 0, 20);
        layout.addView(versionText);

        TextView aboutText = new TextView(this);
        String aboutContent = "<h1>What is MAPS?</h1>" +
                "<p>MAPS - which the observant might notice is SPAM spelled backwards - works on a simple principal that is commonly used with Instant Messenger (IM) clients such as AOL's Instant Messenger or Microsoft's Messenger. That is that with most IM clients you need to get the permission of the person you want to message before you can send them an instant message. MAPS considers all email spam and returns it to the sender unless the email is from somebody on your white list.</p>"
                +
                "<p>Now white lists are not new but maintaining a white list is a bother. So MAPS automates the maintaining of the that white list by putting the responsibility of maintaining it on the people who wish to email you. MAPS also seeks to make it easy for real people, not spammers, to request permission to email you. Here's how it works....</p>"
                +
                "<p>Email that is delivered to you is passed through a filter (maps filter) which processes your email like so:</p>"
                +
                "<ul><li>Extract senders email address - no sender address (and no envelope address)? Discard the email</li>"
                +
                "<li>Check to see if the sender is on your white list - if so deliver the mail</li>"
                +
                "<li>Check to see if the sender is on your black list - if so return a message telling the sender that s/he is blocked from emailing you.<br></li>"
                +
                "<li>Check to see if the sender is on your null list - if so discard the email<br></li>" +
                "<li>Otherwise send the sender a bounce back message with a link for them to quickly register. Also, save their email so it can be delivered when they register<br><br></li></ul>"
                +
                "<p>As you can see this algorithm will greatly reduce your spam. Also, it's easy for real people to register. Spammers typically do not read any email returning to them so they never register!</p>"
                +
                "<h1>What to do if you get a bounce back/register email from MAPS?</h1>" +
                "<p>If you receive a bounce back/register email that means you are not yet on my white list. You can register by clicking the link and then typing your name. That's it! You will then be added to my white list and your previous email will be delivered. Also, all future emails from your email address will be automatically delivered. Note, I reserve the right to remove you from my white list and optionally add you to my null or black lists.</p>"
                +
                "<h1>What to do if you get a black list bounce back email from MAPS?</h1>" +
                "<p>Not much you can do. I've blacklisted you for a reason. I guess you could attempt to contact me another way but chances are I also blocked you phone number from calling or texting me.</p>"
                +
                "<h1>What to do if you find yourself on my null list?</h1>" +
                "<p>Nothing! It's a null list. Your email would have been silently discarded so how would you know? Note I can't even see it - it was not delivered to me.</p>"
                +
                "<p>Designed and developed by <a href=\"mailto:Andrew@DeFaria.com\">Andrew DeFaria</a> - <a href=\"https://defaria.com\">https://defaria.com</a></p>";
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            aboutText.setText(Html.fromHtml(aboutContent, Html.FROM_HTML_MODE_LEGACY));
        } else {
            aboutText.setText(Html.fromHtml(aboutContent));
        }
        aboutText.setTextColor(Color.GREEN);
        aboutText.setMovementMethod(android.text.method.LinkMovementMethod.getInstance());
        aboutText.setLinksClickable(true);
        layout.addView(aboutText);

        scrollView.addView(layout);
        builder.setView(scrollView);
        builder.setPositiveButton("OK", null);
        builder.show();
    }

    private void showInputDialog(String title, final String action) {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle(title);

        final EditText input = new EditText(this);
        input.setInputType(InputType.TYPE_CLASS_TEXT);
        input.setPadding(40, 30, 40, 30);
        input.setImeOptions(EditorInfo.IME_ACTION_DONE);
        builder.setView(input);

        builder.setPositiveButton("OK", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                String text = input.getText().toString();
                performAction(usernameField.getText().toString(), passwordField.getText().toString(), action, text,
                        null);
            }
        });
        builder.setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.cancel();
            }
        });

        final AlertDialog dialog = builder.create();

        input.setOnEditorActionListener(new TextView.OnEditorActionListener() {
            @Override
            public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {
                if (actionId == EditorInfo.IME_ACTION_DONE || (event != null
                        && event.getKeyCode() == KeyEvent.KEYCODE_ENTER && event.getAction() == KeyEvent.ACTION_DOWN)) {
                    String text = input.getText().toString();
                    performAction(usernameField.getText().toString(), passwordField.getText().toString(), action, text,
                            null);
                    dialog.dismiss();
                    return true;
                }
                return false;
            }
        });

        dialog.show();
    }

    private void showAddListDialog(final String type, String pattern, String domain) {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Add to " + type + " list");

        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(40, 20, 40, 20);

        TextView patternLabel = new TextView(this);
        patternLabel.setText("Username");
        patternLabel.setTextColor(Color.GRAY);
        layout.addView(patternLabel);

        final EditText patternInput = new EditText(this);
        patternInput.setHint("Username");
        patternInput.setText(pattern);
        layout.addView(patternInput);

        TextView domainLabel = new TextView(this);
        domainLabel.setText("Domain");
        domainLabel.setTextColor(Color.GRAY);
        layout.addView(domainLabel);

        final EditText domainInput = new EditText(this);
        domainInput.setHint("Domain");
        domainInput.setText(domain);
        layout.addView(domainInput);

        TextView retentionLabel = new TextView(this);
        retentionLabel.setText("Retention");
        retentionLabel.setTextColor(Color.GRAY);
        layout.addView(retentionLabel);

        LinearLayout retentionLayout = new LinearLayout(this);
        retentionLayout.setOrientation(LinearLayout.HORIZONTAL);

        final EditText retentionNumInput = new EditText(this);
        retentionNumInput.setHint("Retention");
        retentionNumInput.setInputType(InputType.TYPE_CLASS_NUMBER);
        LinearLayout.LayoutParams numParams = new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.WRAP_CONTENT, 1.0f);
        retentionNumInput.setLayoutParams(numParams);

        final Spinner retentionUnitSpinner = new Spinner(this);
        String[] units = { "days", "weeks", "months", "years" };
        ArrayAdapter<String> adapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, units);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        retentionUnitSpinner.setAdapter(adapter);

        retentionLayout.addView(retentionNumInput);
        retentionLayout.addView(retentionUnitSpinner);
        layout.addView(retentionLayout);

        TextView commentLabel = new TextView(this);
        commentLabel.setText("Comment");
        commentLabel.setTextColor(Color.GRAY);
        layout.addView(commentLabel);

        final EditText commentInput = new EditText(this);
        commentInput.setHint("Comment");
        layout.addView(commentInput);

        builder.setView(layout);

        builder.setPositiveButton("Add", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                String retNum = retentionNumInput.getText().toString().trim();
                String retStr = "";
                if (!retNum.isEmpty()) {
                    String unit = (String) retentionUnitSpinner.getSelectedItem();
                    if ("1".equals(retNum) && unit.endsWith("s")) {
                        unit = unit.substring(0, unit.length() - 1);
                    }
                    retStr = retNum + " " + unit;
                }

                new MapsTask("add_" + type, type, 0, patternInput.getText().toString(),
                        domainInput.getText().toString(), 0, retStr,
                        commentInput.getText().toString()).execute(usernameField.getText().toString(),
                                passwordField.getText().toString());
            }
        });
        builder.setNegativeButton("Cancel", null);

        builder.show();
    }

    private void showEditListDialog(final String type, final int sequence, String pattern, String domain, int hits,
            String retention, String comment) {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Edit " + type + " list entry " + sequence);

        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(40, 20, 40, 20);

        TextView patternLabel = new TextView(this);
        patternLabel.setText("Username");
        patternLabel.setTextColor(Color.GRAY);
        layout.addView(patternLabel);

        final EditText patternInput = new EditText(this);
        patternInput.setHint("Username");
        patternInput.setText(pattern);
        layout.addView(patternInput);

        TextView domainLabel = new TextView(this);
        domainLabel.setText("Domain");
        domainLabel.setTextColor(Color.GRAY);
        layout.addView(domainLabel);

        final EditText domainInput = new EditText(this);
        domainInput.setHint("Domain");
        domainInput.setText(domain);
        layout.addView(domainInput);

        TextView hitsLabel = new TextView(this);
        hitsLabel.setText("Hit Count");
        hitsLabel.setTextColor(Color.GRAY);
        layout.addView(hitsLabel);

        final EditText hitsInput = new EditText(this);
        hitsInput.setHint("Hit Count");
        hitsInput.setInputType(InputType.TYPE_CLASS_NUMBER);
        hitsInput.setText(String.valueOf(hits));
        layout.addView(hitsInput);

        TextView retentionLabel = new TextView(this);
        retentionLabel.setText("Retention");
        retentionLabel.setTextColor(Color.GRAY);
        layout.addView(retentionLabel);

        LinearLayout retentionLayout = new LinearLayout(this);
        retentionLayout.setOrientation(LinearLayout.HORIZONTAL);

        final EditText retentionNumInput = new EditText(this);
        retentionNumInput.setHint("Retention");
        retentionNumInput.setInputType(InputType.TYPE_CLASS_NUMBER);
        LinearLayout.LayoutParams numParams = new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.WRAP_CONTENT, 1.0f);
        retentionNumInput.setLayoutParams(numParams);

        final Spinner retentionUnitSpinner = new Spinner(this);
        String[] units = { "days", "weeks", "months", "years" };
        ArrayAdapter<String> adapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, units);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        retentionUnitSpinner.setAdapter(adapter);

        String currentNum = "";
        int unitIndex = 0;
        if (retention != null && !retention.isEmpty()) {
            String[] parts = retention.trim().split("\\s+");
            if (parts.length > 0) {
                currentNum = parts[0];
            }
            if (parts.length > 1) {
                String u = parts[1].toLowerCase();
                if (u.startsWith("week"))
                    unitIndex = 1;
                else if (u.startsWith("month"))
                    unitIndex = 2;
                else if (u.startsWith("year"))
                    unitIndex = 3;
            }
        }
        retentionNumInput.setText(currentNum);
        retentionUnitSpinner.setSelection(unitIndex);

        retentionLayout.addView(retentionNumInput);
        retentionLayout.addView(retentionUnitSpinner);
        layout.addView(retentionLayout);

        TextView commentLabel = new TextView(this);
        commentLabel.setText("Comment");
        commentLabel.setTextColor(Color.GRAY);
        layout.addView(commentLabel);

        final EditText commentInput = new EditText(this);
        commentInput.setHint("Comment");
        commentInput.setText(comment);
        layout.addView(commentInput);

        builder.setView(layout);

        builder.setPositiveButton("Update", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                int h = 0;
                try {
                    h = Integer.parseInt(hitsInput.getText().toString());
                } catch (NumberFormatException e) {
                }

                String retNum = retentionNumInput.getText().toString().trim();
                String retStr = "";
                if (!retNum.isEmpty()) {
                    String unit = (String) retentionUnitSpinner.getSelectedItem();
                    if ("1".equals(retNum) && unit.endsWith("s")) {
                        unit = unit.substring(0, unit.length() - 1);
                    }
                    retStr = retNum + " " + unit;
                }

                new MapsTask("update_list", type, sequence, patternInput.getText().toString(),
                        domainInput.getText().toString(), h, retStr,
                        commentInput.getText().toString()).execute(usernameField.getText().toString(),
                                passwordField.getText().toString());
            }
        });
        builder.setNegativeButton("Cancel", null);

        builder.show();
    }

    private void addMenuButton(String text, final String action) {
        Button button = new Button(this);
        button.setText(text);
        button.setTextSize(12);
        button.setBackgroundColor(Color.parseColor("#36454F"));
        button.setTextColor(Color.WHITE);
        button.setTag(action);
        button.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if ("logout".equals(action)) {
                    isLoggedIn = false;
                    storedCookie = null;
                    storedUserid = null;
                    loginLayout.setVisibility(View.VISIBLE);
                    menuLayout.setVisibility(View.GONE);
                    menuButton.setVisibility(View.GONE);
                    outputView.setText("");
                    passwordField.setText("");
                    backButton.setVisibility(View.GONE);
                } else {
                    performAction(usernameField.getText().toString(), passwordField.getText().toString(), action);
                }
            }
        });
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                0, LinearLayout.LayoutParams.WRAP_CONTENT, 1.0f);
        button.setLayoutParams(params);
        menuLayout.addView(button);
    }

    private void styleLabel(TextView label) {
        label.setTextColor(Color.WHITE);
        label.setTextSize(18);
        label.setPadding(0, 10, 0, 5);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        label.setLayoutParams(params);
    }

    private void styleEditText(EditText editText, String hint) {
        editText.setHint(hint);
        editText.setTextColor(Color.WHITE);
        editText.setHintTextColor(Color.LTGRAY);

        GradientDrawable shape = new GradientDrawable();
        shape.setShape(GradientDrawable.RECTANGLE);
        shape.setCornerRadius(20);
        shape.setColor(Color.BLUE);
        shape.setStroke(3, Color.parseColor("#CCCCCC"));

        editText.setBackground(shape);
        editText.setPadding(40, 30, 40, 30);

        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        params.setMargins(0, 20, 0, 20);
        editText.setLayoutParams(params);
    }

    private TextView createActionButton(String text, int color, View.OnClickListener listener) {
        TextView button = new TextView(MainActivity.this);
        button.setText(text);
        button.setTextColor(Color.WHITE);
        button.setTextSize(12);
        button.setTypeface(Typeface.DEFAULT_BOLD);
        button.setGravity(Gravity.CENTER);

        GradientDrawable circle = new GradientDrawable();
        circle.setShape(GradientDrawable.OVAL);
        circle.setColor(color);
        button.setBackground(circle);

        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(60, 60);
        params.setMargins(10, 0, 0, 0);
        button.setLayoutParams(params);

        button.setOnClickListener(listener);
        return button;
    }

    private void addStatRow(TableLayout table, String label, int value, final String action) {
        TableRow row = new TableRow(this);
        if (action != null && value > 0) {
            row.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    performAction(usernameField.getText().toString(), passwordField.getText().toString(), action);
                }
            });
        }

        TextView labelView = new TextView(this);
        labelView.setText(label);
        labelView.setTextColor(Color.GREEN);
        labelView.setTextSize(16);
        labelView.setPadding(10, 10, 10, 10);
        row.addView(labelView);

        TextView valueView = new TextView(this);
        valueView.setText(String.valueOf(value));
        valueView.setTextColor(Color.GREEN);
        valueView.setTextSize(16);
        valueView.setGravity(Gravity.END);
        valueView.setPadding(10, 10, 10, 10);
        row.addView(valueView);

        table.addView(row);
    }

    private void resetWebView() {
        if (currentWebView != null) {
            contentFrame.removeView(currentWebView);
            currentWebView.destroy();
            currentWebView = null;
        }
        scrollView.setVisibility(View.VISIBLE);
    }

    private void loadNextPage() {
        currentOffset += PAGE_SIZE;
        performAction(usernameField.getText().toString(), passwordField.getText().toString(), lastListAction,
                currentOffset);
    }

    private void performAction(String user, String pass, String action) {
        performAction(user, pass, action, null, 0);
    }

    private void performAction(String user, String pass, String action, int offset) {
        performAction(user, pass, action, null, offset);
    }
    
    private void performAction(String user, String pass, String action, final String date, int offset) {
        resetWebView();
        lastListAction = action;
        currentOffset = offset;
        isLoading = true;
        if (offset == 0) {
            outputContainer.removeAllViews();
            outputContainer.addView(outputView);
            outputView.setText("Loading " + action + "...");
            if (navButtonsLayout != null) {
                navButtonsLayout.setVisibility(View.GONE);
            }
        } else {
            outputContainer.addView(loadingSpinner);
        }

        for (int i = 0; i < menuLayout.getChildCount(); i++) {
            View v = menuLayout.getChildAt(i);
            String tag = (String) v.getTag();
            if (tag != null && (tag.equals(action) || action.startsWith("last_page_" + tag))) {
                v.setBackgroundColor(Color.parseColor("#4488FF"));
            } else {
                v.setBackgroundColor(Color.parseColor("#36454F"));
            }
        }

        String dateParam = "";
        if (date != null) {
            dateParam = date;
        }
        if ("search".equals(action)) {
            new MapsTask(action, lastSearchQuery, null, offset).execute(user, pass);
        } else {
            new MapsTask(action, dateParam, offset).execute(user, pass);
        }
    }

    private void checkEntryAndShowDialog(String type, String sender) {
        new CheckEntryTask(type, sender).execute();
    }

    private class CheckEntryTask extends AsyncTask<String, Void, String> {
        private String mType;
        private String mSender;

        public CheckEntryTask(String type, String sender) {
            mType = type;
            mSender = sender;
        }

        @Override
        protected String doInBackground(String... params) {
            try {
                String url = API_URL + "?action=check_list_entry&userid=" + storedUserid +
                        "&type=" + mType + "&sender=" + URLEncoder.encode(mSender, "UTF-8");
                return sendRequest(url, "GET", null, storedCookie);
            } catch (Exception e) {
                return "Error: " + e.getMessage();
            }
        }

        @Override
        protected void onPostExecute(String result) {
            try {
                JSONObject json = new JSONObject(result);
                if ("found".equals(json.optString("status"))) {
                    JSONObject data = json.getJSONObject("data");
                    int sequence = data.optInt("sequence");
                    String pattern = "null".equals(data.optString("pattern", "")) ? "" : data.optString("pattern", "");
                    String domain = "null".equals(data.optString("domain", "")) ? "" : data.optString("domain", "");
                    int hits = data.optInt("hit_count");
                    String retention = "null".equals(data.optString("retention", "")) ? ""
                            : data.optString("retention", "");
                    String comment = "null".equals(data.optString("comment", "")) ? "" : data.optString("comment", "");

                    showEditListDialog(mType, sequence, pattern, domain, hits, retention, comment);
                } else {
                    String p = "";
                    String d = mSender;
                    if (mSender.contains("@")) {
                        String[] parts = mSender.split("@", 2);
                        p = parts[0];
                        d = parts[1];
                    }
                    showAddListDialog(mType, p, d);
                }
            } catch (Exception e) {
                String p = "";
                String d = mSender;
                if (mSender.contains("@")) {
                    String[] parts = mSender.split("@", 2);
                    p = parts[0];
                    d = parts[1];
                }
                showAddListDialog(mType, p, d);
            }
        }
    }

    private String sendRequest(String urlStr, String method, String postParams, String cookie) throws Exception {
        URL url = new URL(urlStr);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod(method);
        if (cookie != null) {
            conn.setRequestProperty("Cookie", cookie);
        }

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

    private void performAction(String user, String pass, String action, String sender, String timestamp) {
        resetWebView();
        if ("search".equals(action)) {
            lastSearchQuery = sender;
        }
        if ("search".equals(action) || "check_address".equals(action)) {
            for (int i = 0; i < menuLayout.getChildCount(); i++) {
                menuLayout.getChildAt(i).setBackgroundColor(Color.parseColor("#36454F"));
            }
        }
        outputContainer.removeAllViews();
        outputContainer.addView(outputView);
        outputView.setText("Loading message...");
        new MapsTask(action, sender, timestamp, 0).execute(user, pass);
    }

    private void showColoredToast(String message, boolean isError) {
        TextView textView = new TextView(this);
        textView.setText(message);
        textView.setTextColor(Color.WHITE);
        textView.setPadding(40, 20, 40, 20);
        textView.setTextSize(16);
        textView.setTypeface(Typeface.DEFAULT_BOLD);

        GradientDrawable shape = new GradientDrawable();
        shape.setShape(GradientDrawable.RECTANGLE);
        shape.setCornerRadius(20);
        shape.setColor(isError ? Color.RED : Color.parseColor("#006400"));

        textView.setBackground(shape);

        android.widget.Toast toast = new android.widget.Toast(this);
        toast.setDuration(android.widget.Toast.LENGTH_LONG);
        toast.setView(textView);
        toast.show();
    }

    private class MapsTask extends AsyncTask<String, Void, String> {
        private String mAction;
        private String mDate;
        private String mSender;
        private String mTimestamp;
        private String actionMessage;
        private boolean isActionError = false;
        private int mOffset;
        private boolean isBottomRequest = false;
        private int mLines = PAGE_SIZE;
        private String mType;
        private int mSequence;
        private String mPattern;
        private String mDomain;
        private int mHits;
        private String mRetention;
        private String mComment;

        public MapsTask(String action, String date, int offset) {
            mAction = action;
            mDate = date;
            mOffset = offset;
        }

        public MapsTask(String action, String sender, String timestamp, int offset) {
            mAction = action;
            mSender = sender;
            mTimestamp = timestamp;
            mOffset = offset;
        }

        public MapsTask(String action) {
            this(action, "", 0);
        }

        public MapsTask(String action, String type, int sequence, String pattern, String domain, int hits,
                String retention, String comment) {
            mAction = action;
            mType = type;
            mSequence = sequence;
            mPattern = pattern;
            mDomain = domain;
            mHits = hits;
            mRetention = retention;
            mComment = comment;
        }

        @Override
        protected String doInBackground(String... params) {
            try {
                String username = params[0];
                String password = params[1];

                if (storedCookie == null) {
                    // 1. Login
                    String loginParams = "action=login&username=" + URLEncoder.encode(username, "UTF-8") +
                            "&password=" + URLEncoder.encode(password, "UTF-8");

                    URL url = new URL(API_URL);
                    HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                    conn.setRequestMethod("POST");
                    conn.setDoOutput(true);
                    OutputStream os = conn.getOutputStream();
                    os.write(loginParams.getBytes());
                    os.flush();
                    os.close();

                    BufferedReader in = new BufferedReader(new InputStreamReader(conn.getInputStream()));
                    StringBuilder response = new StringBuilder();
                    String inputLine;
                    while ((inputLine = in.readLine()) != null) {
                        response.append(inputLine);
                    }
                    in.close();

                    JSONObject loginJson = new JSONObject(response.toString());

                    if (!"success".equals(loginJson.optString("status"))) {
                        return "Login Failed: " + loginJson.optString("message");
                    }

                    storedUserid = loginJson.getString("userid");

                    List<String> cookies = conn.getHeaderFields().get("Set-Cookie");
                    if (cookies != null) {
                        StringBuilder sb = new StringBuilder();
                        for (String cookie : cookies) {
                            if (sb.length() > 0)
                                sb.append("; ");
                            sb.append(cookie.split(";", 2)[0]);
                        }
                        storedCookie = sb.toString();
                    }

                    SharedPreferences prefs = getSharedPreferences("MAPSPrefs", MODE_PRIVATE);
                    SharedPreferences.Editor editor = prefs.edit();
                    editor.putString("cookie", storedCookie);
                    editor.putString("userid", storedUserid);
                    editor.apply();
                }

                // 2. Perform Action
                if (mAction.startsWith("add_")) {
                    String sender = mSender;
                    if (mPattern != null || mDomain != null) {
                        String p = mPattern != null ? mPattern : "";
                        String d = mDomain != null ? mDomain : "";
                        if (!p.isEmpty() && !d.isEmpty())
                            sender = p + "@" + d;
                        else if (!d.isEmpty())
                            sender = "@" + d;
                        else
                            sender = p;
                    }
                    String url = API_URL + "?action=" + mAction + "&userid=" + storedUserid + "&sender="
                            + URLEncoder.encode(sender, "UTF-8");
                    if (mRetention != null && !mRetention.isEmpty())
                        url += "&retention=" + URLEncoder.encode(mRetention, "UTF-8");
                    if (mComment != null && !mComment.isEmpty())
                        url += "&comment=" + URLEncoder.encode(mComment, "UTF-8");
                    String response = sendRequest(url, "GET", null, storedCookie);
                    JSONObject json = new JSONObject(response);

                    actionMessage = json.optString("message");
                    if (!"success".equals(json.optString("status"))) {
                        isActionError = true;
                    }

                    // On success, refresh the returned list
                    mAction = "returned";
                    if (mDate == null || mDate.isEmpty()) {
                        mDate = new SimpleDateFormat("yyyy-MM-dd", Locale.US).format(new Date());
                    }
                    // Fall through to "returned" logic below
                }

                if ("update_list".equals(mAction)) {
                    String url = API_URL + "?action=update_list&userid=" + storedUserid +
                            "&type=" + mType +
                            "&sequence=" + mSequence +
                            "&pattern=" + URLEncoder.encode(mPattern, "UTF-8") +
                            "&domain=" + URLEncoder.encode(mDomain, "UTF-8") +
                            "&hit_count=" + mHits +
                            "&retention=" + URLEncoder.encode(mRetention, "UTF-8") +
                            "&comment=" + URLEncoder.encode(mComment, "UTF-8");
                    String response = sendRequest(url, "GET", null, storedCookie);
                    JSONObject json = new JSONObject(response);
                    actionMessage = json.optString("message");
                    if (!"success".equals(json.optString("status"))) {
                        isActionError = true;
                    }
                    // Refresh the list
                    mAction = mType;
                    // Fall through to list loading logic
                }

                if (mAction.startsWith("last_page_")) {
                    isBottomRequest = true;
                    String realAction = mAction.substring(10);

                    if ("white".equals(realAction) || "black".equals(realAction) || "null".equals(realAction)) {
                        mAction = realAction;
                        String url = API_URL + "?action=get_whole_list&userid=" + storedUserid + "&type=" + realAction;
                        String response = sendRequest(url, "GET", null, storedCookie);
                        try {
                            JSONObject json = new JSONObject(response);
                            if ("success".equals(json.optString("status"))) {
                                JSONArray data = json.getJSONArray("data");
                                mLines = data.length();
                                mOffset = 0;
                            }
                        } catch (Exception e) {
                        }
                        return "JSON:" + response;
                    }

                    String statsUrl = API_URL + "?action=stats&userid=" + storedUserid;
                    String statsResponse = sendRequest(statsUrl, "GET", null, storedCookie);
                    JSONObject statsJson = new JSONObject(statsResponse);

                    if (!"success".equals(statsJson.optString("status"))) {
                        return "Stats Failed: " + statsJson.optString("message");
                    }

                    JSONObject data = statsJson.getJSONObject("data");
                    int total = 0;
                    if ("returned".equals(realAction))
                        total = data.optInt("returned");
                    else if ("white_today".equals(realAction))
                        total = data.optInt("whitelist");
                    else if ("black_today".equals(realAction))
                        total = data.optInt("blacklist");
                    else if ("null_today".equals(realAction))
                        total = data.optInt("nulllist");

                    mOffset = 0;
                    mLines = total > 0 ? total : PAGE_SIZE;
                    mAction = realAction;
                }

                if ("stats".equals(mAction)) {
                    String statsUrl = API_URL + "?action=stats&userid=" + storedUserid;
                    String statsResponse = sendRequest(statsUrl, "GET", null, storedCookie);
                    JSONObject statsJson = new JSONObject(statsResponse);

                    if (!"success".equals(statsJson.optString("status"))) {
                        return "Stats Failed: " + statsJson.optString("message");
                    }

                    JSONObject data = statsJson.getJSONObject("data");

                    return "JSON:" + statsResponse;
                } else if ("search".equals(mAction)) {
                    String url = API_URL + "?action=search&userid=" + storedUserid + "&str="
                            + URLEncoder.encode(mSender, "UTF-8");
                    String response = sendRequest(url, "GET", null, storedCookie);
                    return "JSON:" + response;
                } else if ("check_address".equals(mAction)) {
                    String url = API_URL + "?action=check_address&userid=" + storedUserid + "&email="
                            + URLEncoder.encode(mSender, "UTF-8");
                    String response = sendRequest(url, "GET", null, storedCookie);
                    return "JSON:" + response;
                } else if ("top20".equals(mAction)) {
                    String url = API_URL + "?action=" + mAction + "&userid=" + storedUserid;
                    String response = sendRequest(url, "GET", null, storedCookie);
                    return "JSON:" + response;
                } else if ("returned".equals(mAction) || mAction.endsWith("_today")) {
                    String apiAction = "returned";
                    String typeVal = "returned";
                    if (mAction.endsWith("_today")) {
                        typeVal = mAction.replace("_today", "");
                    }

                    String url = API_URL + "?action=" + apiAction + "&userid=" + storedUserid + "&date=" + mDate
                            + "&start=" + mOffset + "&lines=" + mLines + "&type=" + typeVal;
                    String response = sendRequest(url, "GET", null, storedCookie);
                    // Return raw JSON for post-processing into cards
                    return "JSON:" + response;
                } else if ("display".equals(mAction)) {
                    String url = API_URL + "?action=display&userid=" + storedUserid + "&sender="
                            + URLEncoder.encode(mSender, "UTF-8") +
                            "&msg_date=" + URLEncoder.encode(mTimestamp, "UTF-8") +
                            "&header_color=%2336454F";
                    String response = sendRequest(url, "GET", null, storedCookie);
                    return "JSON:" + response;
                } else if ("white".equals(mAction) || "black".equals(mAction) || "null".equals(mAction)) {
                    String url = API_URL + "?action=" + mAction + "&userid=" + storedUserid + "&start=" + mOffset
                            + "&lines=" + mLines;
                    String response = sendRequest(url, "GET", null, storedCookie);
                    return "JSON:" + response;
                } else if ("full_stats".equals(mAction)) {
                    String url = API_URL + "?action=full_stats&userid=" + storedUserid;
                    String response = sendRequest(url, "GET", null, storedCookie);
                    return "JSON:" + response;
                }
                return "Unknown action: " + mAction;

            } catch (Exception e) {
                return "Error: " + e.getMessage();
            }
        }

        @Override
        protected void onPostExecute(String result) {
            if (mOffset == 0 || isBottomRequest) {
                outputContainer.removeAllViews();
            } else {
                outputContainer.removeView(loadingSpinner);
            }
            isLoading = false;
            if (isBottomRequest) {
                MainActivity.this.currentOffset = mOffset + mLines - PAGE_SIZE;
            } else {
                MainActivity.this.currentOffset = mOffset;
            }
            if (!"display".equals(mAction) && !"check_address".equals(mAction)) {
                MainActivity.this.lastListAction = mAction;
            }

            if (actionMessage != null) {
                showColoredToast(actionMessage, isActionError);
            }

            if (result.startsWith("Error") || result.startsWith("Login Failed")) {
                storedCookie = null;
                storedUserid = null;
                SharedPreferences prefs = getSharedPreferences("MAPSPrefs", MODE_PRIVATE);
                SharedPreferences.Editor editor = prefs.edit();
                editor.remove("cookie");
                editor.remove("userid");
                editor.apply();
            }

            if (result.startsWith("WEBVIEW:")) {
                String url = result.substring(8);
                WebView webView = new WebView(MainActivity.this);
                webView.getSettings().setJavaScriptEnabled(true);
                webView.getSettings().setBuiltInZoomControls(true);
                webView.getSettings().setDisplayZoomControls(false);
                webView.getSettings().setSupportZoom(true);

                CookieManager cookieManager = CookieManager.getInstance();
                cookieManager.setAcceptCookie(true);
                if (storedCookie != null) {
                    String[] cookies = storedCookie.split(";");
                    for (String cookie : cookies) {
                        cookieManager.setCookie("https://defaria.com/maps/bin/", cookie.trim());
                    }
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    cookieManager.flush();
                }
                webView.loadUrl(url);
                scrollView.setVisibility(View.GONE);
                contentFrame.addView(webView);
                currentWebView = webView;
                return;
            }

            if (result.startsWith("JSON:")) {
                try {
                    JSONObject json = new JSONObject(result.substring(5));
                    if (!"success".equals(json.optString("status"))) {
                        outputContainer.addView(outputView);
                        outputView.setText("Error: " + json.optString("message"));
                    } else {
                        if ("display".equals(mAction) || "full_stats".equals(mAction)) {
                            String html = json.getString("data");
                            WebView webView = new WebView(MainActivity.this);
                            webView.setWebViewClient(new WebViewClient() {
                                @Override
                                public boolean shouldOverrideUrlLoading(WebView view, String url) {
                                    if (url.startsWith("maps://")) {
                                        Uri uri = Uri.parse(url);
                                        if ("view".equals(uri.getHost())) {
                                            String type = uri.getQueryParameter("type");
                                            String date = uri.getQueryParameter("date");
                                            if (type != null && date != null) {
                                                String action = type;
                                                // Map "nulllist", "whitelist", "blacklist" to app-friendly names if needed
                                                // App seems to support "returned", "white_today" (implies type="white").
                                                // But let's pass generic type logic.
                                                // If we pass "whitelist", "returned", etc with date, we just need to ensure MapsTask handles it.
                                                // MapsTask logic (lines 1350+):
                                                // if returned/endedWith _today -> uses typeVal from action (stripped of _today, or just "returned").
                                                // So if we pass action="whitelist_today", typeVal="whitelist".
                                                // Server expects "whitelist". This matches!
                                                // So we can map "nulllist" -> "nulllist_today", etc.
                                                // But wait, "nulllist" is the type from api.cgi $_.
                                                // So action = type + "_today".
                                                // Exception: "returned". If type is "returned", action="returned".
                                                
                                                if ("returned".equals(type)) {
                                                    action = "returned";
                                                } else {
                                                    action = type + "_today";
                                                }
                                                performAction(storedUserid, storedCookie, action, date, 0);
                                                return true;
                                            } else if (type != null) {
                                                 String action = type;
                                                 if ("whitelist".equals(type)) action = "white";
                                                 if ("blacklist".equals(type)) action = "black";
                                                 if ("nulllist".equals(type)) action = "null";
                                                 performAction(storedUserid, storedCookie, action, 0); // Reuse non-date overload
                                                 return true;
                                            }
                                        }
                                    }
                                    return false;
                                }
                            });
                            webView.setBackgroundColor(Color.WHITE);
                            webView.getSettings().setJavaScriptEnabled(true);
                            webView.getSettings().setBuiltInZoomControls(true);
                            webView.getSettings().setDisplayZoomControls(false);
                            webView.getSettings().setSupportZoom(true);
                            if (Build.VERSION.SDK_INT >= 29) { // Build.VERSION_CODES.Q
                                webView.getSettings().setForceDark(WebSettings.FORCE_DARK_OFF);
                            }

                            CookieManager cookieManager = CookieManager.getInstance();
                            cookieManager.setAcceptCookie(true);
                            if (storedCookie != null) {
                                String[] cookies = storedCookie.split(";");
                                for (String cookie : cookies) {
                                    cookieManager.setCookie("https://defaria.com/maps/bin/", cookie.trim());
                                }
                            }
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                                cookieManager.flush();
                            }

                            FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(
                                    FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT);
                            webView.setLayoutParams(params);
                            webView.loadDataWithBaseURL("https://defaria.com/maps/bin/", html, "text/html", "UTF-8",
                                    null);
                            scrollView.setVisibility(View.GONE);
                            contentFrame.addView(webView);
                            currentWebView = webView;
                        } else if ("check_address".equals(mAction)) {
                            String message = json.optString("message");

                            LinearLayout card = new LinearLayout(MainActivity.this);
                            card.setOrientation(LinearLayout.VERTICAL);
                            card.setPadding(20, 20, 20, 20);
                            card.setBackgroundColor(Color.BLACK);
                            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                                    LinearLayout.LayoutParams.MATCH_PARENT,
                                    LinearLayout.LayoutParams.WRAP_CONTENT);
                            params.setMargins(0, 0, 0, 20);
                            card.setLayoutParams(params);

                            TextView msgView = new TextView(MainActivity.this);
                            msgView.setText(message);
                            msgView.setTextColor(Color.GREEN);
                            msgView.setTextSize(16);
                            card.addView(msgView);
                            outputContainer.addView(card);
                        } else if ("stats".equals(mAction)) {
                            JSONObject data = json.getJSONObject("data");

                            // Update buttons with counts
                            for (int i = 0; i < menuLayout.getChildCount(); i++) {
                                View v = menuLayout.getChildAt(i);
                                if (v instanceof Button) {
                                    Button b = (Button) v;
                                    String tag = (String) b.getTag();
                                    int count = 0;
                                    String label = "";

                                    if ("returned".equals(tag)) {
                                        count = data.optInt("returned");
                                        label = "Returned";
                                    } else if ("white_today".equals(tag)) {
                                        count = data.optInt("whitelist");
                                        label = "White";
                                    } else if ("black_today".equals(tag)) {
                                        count = data.optInt("blacklist");
                                        label = "Black";
                                    } else if ("null_today".equals(tag)) {
                                        count = data.optInt("nulllist");
                                        label = "Null";
                                    }

                                    if (!label.isEmpty()) {
                                        b.setText(label + " " + count);
                                        b.setEnabled(count > 0);
                                        b.setAlpha(count > 0 ? 1.0f : 0.5f);
                                    }
                                }
                            }

                            LinearLayout card = new LinearLayout(MainActivity.this);
                            card.setOrientation(LinearLayout.VERTICAL);
                            card.setBackgroundColor(Color.BLACK);
                            LinearLayout.LayoutParams cardParams = new LinearLayout.LayoutParams(
                                    LinearLayout.LayoutParams.MATCH_PARENT,
                                    LinearLayout.LayoutParams.WRAP_CONTENT);
                            cardParams.setMargins(40, 20, 40, 20);
                            card.setLayoutParams(cardParams);
                            card.setPadding(40, 40, 40, 40);

                            TextView title = new TextView(MainActivity.this);
                            String time = new SimpleDateFormat("h:mm a", Locale.US).format(new Date()).toLowerCase();
                            title.setText("Today's Activity\nas of " + time);
                            title.setTextSize(20);
                            title.setTypeface(null, Typeface.BOLD);
                            title.setTextColor(Color.YELLOW);
                            title.setGravity(Gravity.CENTER);
                            title.setPadding(0, 0, 0, 30);
                            card.addView(title);

                            TableLayout table = new TableLayout(MainActivity.this);
                            table.setColumnStretchable(1, true);

                            addStatRow(table, "Processed", data.optInt("processed"), null);
                            addStatRow(table, "Whitelist", data.optInt("whitelist"), null);
                            addStatRow(table, "Returned", data.optInt("returned"), null);
                            addStatRow(table, "Blacklist", data.optInt("blacklist"), null);
                            addStatRow(table, "Nulllist", data.optInt("nulllist"), null);

                            card.addView(table);
                            outputContainer.addView(card);
                        } else {
                            JSONArray data = json.getJSONArray("data");
                            if (data.length() == 0) {
                                if (mOffset == 0) {
                                    outputContainer.addView(outputView);
                                    outputView.setText("No returned emails found for " + mDate);
                                }
                            }
                            if ("top20".equals(mAction)) {
                                TableLayout table = new TableLayout(MainActivity.this);
                                table.setLayoutParams(new LinearLayout.LayoutParams(
                                        LinearLayout.LayoutParams.MATCH_PARENT,
                                        LinearLayout.LayoutParams.WRAP_CONTENT));
                                table.setColumnStretchable(1, true);
                                table.setBackgroundColor(Color.BLACK);

                                TableRow header = new TableRow(MainActivity.this);
                                TextView h0 = new TextView(MainActivity.this);
                                h0.setText("#");
                                h0.setTypeface(null, Typeface.BOLD);
                                h0.setTextColor(Color.GREEN);
                                h0.setPadding(10, 10, 10, 10);
                                header.addView(h0);

                                TextView h1 = new TextView(MainActivity.this);
                                h1.setText("Domain");
                                h1.setTypeface(null, Typeface.BOLD);
                                h1.setTextColor(Color.GREEN);
                                h1.setPadding(10, 10, 10, 10);
                                header.addView(h1);

                                TextView h2 = new TextView(MainActivity.this);
                                h2.setText("Returns");
                                h2.setTypeface(null, Typeface.BOLD);
                                h2.setTextColor(Color.GREEN);
                                h2.setGravity(Gravity.END);
                                h2.setPadding(10, 10, 10, 10);
                                header.addView(h2);
                                table.addView(header);

                                for (int i = 0; i < data.length(); i++) {
                                    JSONObject item = data.getJSONObject(i);
                                    final String domain = item.optString("domain");
                                    int count = item.optInt("count");

                                    TableRow row = new TableRow(MainActivity.this);

                                    TextView numView = new TextView(MainActivity.this);
                                    numView.setText(String.valueOf(i + 1));
                                    numView.setTextColor(Color.WHITE);
                                    numView.setTextSize(12);
                                    numView.setTypeface(Typeface.DEFAULT_BOLD);
                                    numView.setGravity(Gravity.CENTER);
                                    GradientDrawable numShape = new GradientDrawable();
                                    numShape.setShape(GradientDrawable.OVAL);
                                    numShape.setColor(Color.parseColor("#36454F"));
                                    numView.setBackground(numShape);
                                    TableRow.LayoutParams numParams = new TableRow.LayoutParams(60, 60);
                                    numParams.setMargins(10, 10, 10, 10);
                                    numView.setLayoutParams(numParams);
                                    numView.setOnClickListener(new View.OnClickListener() {
                                        @Override
                                        public void onClick(View v) {
                                            new AlertDialog.Builder(MainActivity.this)
                                                    .setTitle("Confirm Null List")
                                                    .setMessage("Add " + domain + " to null list?")
                                                    .setPositiveButton("Yes", new DialogInterface.OnClickListener() {
                                                        @Override
                                                        public void onClick(DialogInterface dialog, int which) {
                                                            performAction(usernameField.getText().toString(),
                                                                    passwordField.getText().toString(),
                                                                    "add_null", domain, null);
                                                        }
                                                    })
                                                    .setNegativeButton("No", null)
                                                    .show();
                                        }
                                    });
                                    row.addView(numView);

                                    TextView domainView = new TextView(MainActivity.this);
                                    domainView.setText(domain);
                                    domainView.setTextColor(Color.YELLOW);
                                    domainView.setPadding(10, 10, 10, 10);
                                    domainView.setOnClickListener(new View.OnClickListener() {
                                        @Override
                                        public void onClick(View v) {
                                            String url = domain;
                                            if (!url.startsWith("http://") && !url.startsWith("https://")) {
                                                url = "http://" + url;
                                            }
                                            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
                                            startActivity(intent);
                                        }
                                    });
                                    row.addView(domainView);

                                    TextView countView = new TextView(MainActivity.this);
                                    countView.setText(String.valueOf(count));
                                    countView.setTextColor(Color.GREEN);
                                    countView.setGravity(Gravity.END);
                                    countView.setPadding(10, 10, 10, 10);
                                    row.addView(countView);

                                    table.addView(row);
                                }
                                outputContainer.addView(table);
                            } else if ("search".equals(mAction)) {
                                for (int i = 0; i < data.length(); i++) {
                                    JSONObject item = data.getJSONObject(i);
                                    final String sender = item.getString("sender");
                                    String subject = item.optString("subject", "");
                                    final String timestamp = item.getString("timestamp");

                                    LinearLayout card = new LinearLayout(MainActivity.this);
                                    card.setOrientation(LinearLayout.VERTICAL);
                                    card.setPadding(20, 20, 20, 20);
                                    card.setBackgroundColor(Color.BLACK);
                                    LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                                            LinearLayout.LayoutParams.MATCH_PARENT,
                                            LinearLayout.LayoutParams.WRAP_CONTENT);
                                    params.setMargins(0, 0, 0, 20);
                                    card.setLayoutParams(params);

                                    TextView senderView = new TextView(MainActivity.this);
                                    senderView.setText(sender);
                                    senderView.setTextColor(Color.YELLOW);
                                    senderView.setTextSize(18);
                                    card.addView(senderView);

                                    TextView subjectView = new TextView(MainActivity.this);
                                    subjectView.setText(subject);
                                    subjectView.setTextColor(Color.GREEN);
                                    card.addView(subjectView);

                                    TextView timeView = new TextView(MainActivity.this);
                                    timeView.setText(timestamp);
                                    timeView.setTextColor(Color.GREEN);
                                    timeView.setTextSize(12);
                                    card.addView(timeView);

                                    card.setOnClickListener(new View.OnClickListener() {
                                        @Override
                                        public void onClick(View v) {
                                            performAction(usernameField.getText().toString(),
                                                    passwordField.getText().toString(), "display", sender, timestamp);
                                        }
                                    });

                                    outputContainer.addView(card);
                                }
                            } else if ("white".equals(mAction) || "black".equals(mAction) || "null".equals(mAction)) {
                                for (int i = 0; i < data.length(); i++) {
                                    JSONObject item = data.getJSONObject(i);
                                    final String pattern = "null".equals(item.optString("pattern", "")) ? ""
                                            : item.optString("pattern", "");
                                    final int sequence = item.optInt("sequence", 0);
                                    final String domain = "null".equals(item.optString("domain", "")) ? ""
                                            : item.optString("domain", "");

                                    int hitCount = item.optInt("hit_count", 0);
                                    String lastHit = item.optString("last_hit", "");
                                    String retention = item.optString("retention", "");
                                    if ("null".equals(retention))
                                        retention = "";
                                    String comment = item.optString("comment", "");
                                    if ("null".equals(comment))
                                        comment = "";

                                    LinearLayout card = new LinearLayout(MainActivity.this);
                                    card.setOrientation(LinearLayout.VERTICAL);
                                    card.setPadding(20, 20, 20, 20);
                                    card.setBackgroundColor(Color.BLACK);
                                    LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                                            LinearLayout.LayoutParams.MATCH_PARENT,
                                            LinearLayout.LayoutParams.WRAP_CONTENT);
                                    params.setMargins(0, 0, 0, 20);
                                    card.setLayoutParams(params);

                                    LinearLayout line1 = new LinearLayout(MainActivity.this);
                                    line1.setOrientation(LinearLayout.HORIZONTAL);

                                    String emailText;
                                    if (!pattern.isEmpty() && !domain.isEmpty()) {
                                        emailText = pattern + "@" + domain;
                                    } else if (!domain.isEmpty()) {
                                        emailText = "@" + domain;
                                    } else {
                                        emailText = pattern;
                                    }

                                    TextView seqView = new TextView(MainActivity.this);
                                    seqView.setText(String.valueOf(sequence));
                                    seqView.setTextColor(Color.WHITE);
                                    seqView.setTextSize(14);
                                    seqView.setGravity(Gravity.CENTER);
                                    GradientDrawable seqShape = new GradientDrawable();
                                    seqShape.setShape(GradientDrawable.RECTANGLE);
                                    seqShape.setCornerRadius(30);
                                    seqShape.setColor(Color.BLUE);
                                    seqView.setBackground(seqShape);
                                    LinearLayout.LayoutParams seqParams = new LinearLayout.LayoutParams(
                                            LinearLayout.LayoutParams.WRAP_CONTENT, 60);
                                    seqParams.setMargins(0, 0, 15, 0);
                                    seqView.setMinWidth(60);
                                    seqView.setPadding(10, 0, 10, 0);
                                    seqView.setLayoutParams(seqParams);

                                    final String fType = mAction;
                                    final int fHits = hitCount;
                                    final String fRetention = retention;
                                    final String fComment = comment;
                                    seqView.setOnClickListener(new View.OnClickListener() {
                                        @Override
                                        public void onClick(View v) {
                                            showEditListDialog(fType, sequence, pattern, domain, fHits, fRetention,
                                                    fComment);
                                        }
                                    });
                                    line1.addView(seqView);

                                    TextView emailView = new TextView(MainActivity.this);
                                    emailView.setText(emailText);
                                    emailView.setTextSize(18);
                                    emailView.setTextColor(Color.YELLOW);
                                    LinearLayout.LayoutParams emailParams = new LinearLayout.LayoutParams(
                                            0, LinearLayout.LayoutParams.WRAP_CONTENT, 1.0f);
                                    emailView.setLayoutParams(emailParams);
                                    line1.addView(emailView);

                                    TextView hitsView = new TextView(MainActivity.this);
                                    hitsView.setText("Hits: " + hitCount);
                                    hitsView.setTextColor(Color.GREEN);
                                    line1.addView(hitsView);

                                    card.addView(line1);

                                    String details = "Last Hit: <font color='#FFFFFF'>" + (lastHit.isEmpty() ? "Never" : lastHit) + "</font>" +
                                            (retention.isEmpty() ? "" : " Retention: " + retention) +
                                            (comment.isEmpty() ? "" : " Comment: <font color='#00FFFF'>" + comment + "</font>");

                                    TextView detailsView = new TextView(MainActivity.this);
                                    detailsView.setTextColor(Color.GREEN);
                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                        detailsView.setText(Html.fromHtml(details, Html.FROM_HTML_MODE_LEGACY));
                                    } else {
                                        detailsView.setText(Html.fromHtml(details));
                                    }
                                    detailsView.setPadding(0, 10, 0, 0);
                                    card.addView(detailsView);

                                    outputContainer.addView(card);
                                }
                            } else if ("returned".equals(mAction) || mAction.endsWith("_today")) {
                                for (int i = 0; i < data.length(); i++) {
                                    JSONObject senderObj = data.getJSONObject(i);
                                    String tempSender = senderObj.optString("sender");
                                    if (tempSender.isEmpty()) {
                                        String p = senderObj.optString("pattern", "");
                                        String d = senderObj.optString("domain", "");
                                        if (!p.isEmpty() && !d.isEmpty())
                                            tempSender = p + "@" + d;
                                        else if (!d.isEmpty())
                                            tempSender = "@" + d;
                                        else
                                            tempSender = p;
                                    }
                                    final String senderEmail = tempSender;
                                    JSONArray messages = senderObj.optJSONArray("messages");
                                    if (messages == null)
                                        messages = new JSONArray();

                                    String list = senderObj.optString("list", "None");
                                    int listSeq = senderObj.optInt("sequence", 0);
                                    if (listSeq == 0) {
                                        listSeq = senderObj.optInt("seq", 0);
                                    }
                                    if (listSeq > 0) {
                                        list = list + ":" + listSeq;
                                    }
                                    int hits = senderObj.optInt("hits", senderObj.optInt("hit_count", 0));
                                    String rule = senderObj.optString("rule", "None");
                                    String retention = senderObj.optString("retention", "");
                                    if ("null".equals(retention))
                                        retention = "";
                                    String comment = senderObj.optString("comment", "");
                                    if ("null".equals(comment))
                                        comment = "";

                                    String timestamp = senderObj.optString("timestamp", "");
                                    if (timestamp.isEmpty() && messages.length() > 0) {
                                        timestamp = messages.getJSONObject(0).optString("timestamp", "");
                                    }
                                    String commentOrDate = comment.isEmpty() ? (timestamp.isEmpty() ? mDate : timestamp)
                                            : comment;

                                    LinearLayout card = new LinearLayout(MainActivity.this);
                                    card.setOrientation(LinearLayout.VERTICAL);
                                    card.setPadding(20, 20, 20, 20);
                                    card.setBackgroundColor(Color.BLACK);
                                    LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                                            LinearLayout.LayoutParams.MATCH_PARENT,
                                            LinearLayout.LayoutParams.WRAP_CONTENT);
                                    params.setMargins(0, 0, 0, 20);
                                    card.setLayoutParams(params);

                                    LinearLayout headerLine = new LinearLayout(MainActivity.this);
                                    headerLine.setOrientation(LinearLayout.HORIZONTAL);
                                    headerLine.setGravity(Gravity.CENTER_VERTICAL);

                                    int sequence = mOffset + i + 1;
                                    TextView seqView = new TextView(MainActivity.this);
                                    seqView.setText(String.valueOf(sequence));
                                    seqView.setTextColor(Color.WHITE);
                                    seqView.setTextSize(14);
                                    seqView.setGravity(Gravity.CENTER);
                                    GradientDrawable seqShape = new GradientDrawable();
                                    seqShape.setShape(GradientDrawable.RECTANGLE);
                                    seqShape.setCornerRadius(30);
                                    seqShape.setColor(Color.BLUE);
                                    seqView.setBackground(seqShape);
                                    LinearLayout.LayoutParams seqParams = new LinearLayout.LayoutParams(
                                            LinearLayout.LayoutParams.WRAP_CONTENT, 60);
                                    seqParams.setMargins(0, 0, 15, 0);
                                    seqView.setMinWidth(60);
                                    seqView.setPadding(10, 0, 10, 0);
                                    seqView.setLayoutParams(seqParams);
                                    headerLine.addView(seqView);

                                    TextView senderView = new TextView(MainActivity.this);
                                    senderView.setText(senderEmail);
                                    senderView.setTextSize(18);
                                    senderView.setTextColor(Color.YELLOW);
                                    LinearLayout.LayoutParams senderParams = new LinearLayout.LayoutParams(
                                            0, LinearLayout.LayoutParams.WRAP_CONTENT, 1.0f);
                                    senderView.setLayoutParams(senderParams);
                                    senderView.setOnClickListener(new View.OnClickListener() {
                                        @Override
                                        public void onClick(View v) {
                                            Intent intent = new Intent(Intent.ACTION_SENDTO);
                                            intent.setData(Uri.parse("mailto:" + senderEmail));
                                            startActivity(intent);
                                        }
                                    });
                                    headerLine.addView(senderView);

                                    final TextView detailsView = new TextView(MainActivity.this);
                                    detailsView.setTextSize(14);
                                    detailsView.setTextColor(Color.GREEN);

                                    String detailsText = "<b>List:</b> <font color='#FFFFFF'><b>" + list
                                            + "</b></font> <b>Hits:</b> <font color='#FF00FF'><b>" + hits
                                            + "</b></font> <b>Rule:</b> <font color='#00FFFF'><b>" + rule
                                            + "</b></font>";
                                    if (!retention.isEmpty()) {
                                        detailsText += " <b>Retention:</b> " + retention;
                                    }
                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                        detailsView.setText(Html.fromHtml(detailsText, Html.FROM_HTML_MODE_LEGACY));
                                    } else {
                                        detailsView.setText(Html.fromHtml(detailsText));
                                    }
                                    detailsView.setVisibility(View.VISIBLE);

                                    final String fListType = senderObj.optString("list", "None").toLowerCase();
                                    final int fListSeq = listSeq;
                                    final String fSender = senderEmail;
                                    final int fHits = hits;
                                    final String fRetention = retention;
                                    final String fComment = comment;

                                    if (fListSeq > 0) {
                                        detailsView.setOnClickListener(new View.OnClickListener() {
                                            @Override
                                            public void onClick(View v) {
                                                String p = "", d = fSender;
                                                if (fSender.contains("@")) {
                                                    String[] parts = fSender.split("@", 2);
                                                    p = parts[0];
                                                    d = parts[1];
                                                }
                                                showEditListDialog(fListType, fListSeq, p, d, fHits, fRetention,
                                                        fComment);
                                            }
                                        });
                                    }

                                    TextView timestampView = new TextView(MainActivity.this);
                                    timestampView.setText(commentOrDate);
                                    timestampView.setTextSize(18);
                                    timestampView.setTextColor(Color.GREEN);
                                    LinearLayout.LayoutParams tsParams = new LinearLayout.LayoutParams(
                                            LinearLayout.LayoutParams.WRAP_CONTENT,
                                            LinearLayout.LayoutParams.WRAP_CONTENT);
                                    tsParams.setMargins(0, 0, 20, 0);
                                    timestampView.setLayoutParams(tsParams);

                                    // Add Action Buttons
                                    TextView nukeBtn = createActionButton("N", Color.RED, new View.OnClickListener() {
                                        @Override
                                        public void onClick(View v) {
                                            checkEntryAndShowDialog("null", senderEmail);
                                        }
                                    });
                                    headerLine.addView(nukeBtn);

                                    TextView whiteBtn = createActionButton("W", Color.parseColor("#006400"),
                                            new View.OnClickListener() {
                                                @Override
                                                public void onClick(View v) {
                                                    checkEntryAndShowDialog("white", senderEmail);
                                                }
                                            });
                                    headerLine.addView(whiteBtn);

                                    TextView blackBtn = createActionButton("B", Color.parseColor("#36454F"),
                                            new View.OnClickListener() {
                                                @Override
                                                public void onClick(View v) {
                                                    checkEntryAndShowDialog("black", senderEmail);
                                                }
                                            });
                                    headerLine.addView(blackBtn);

                                    TextView xBtn = createActionButton("x", Color.RED, new View.OnClickListener() {
                                        @Override
                                        public void onClick(View v) {
                                            String domain = senderEmail;
                                            if (domain.contains("@")) {
                                                domain = domain.substring(domain.indexOf("@") + 1);
                                            }
                                            final String fDomain = domain;

                                            new AlertDialog.Builder(MainActivity.this)
                                                    .setTitle("Confirm Null List")
                                                    .setMessage("Add " + fDomain + " to null list?")
                                                    .setPositiveButton("Yes", new DialogInterface.OnClickListener() {
                                                        @Override
                                                        public void onClick(DialogInterface dialog, int which) {
                                                            performAction(usernameField.getText().toString(),
                                                                    passwordField.getText().toString(),
                                                                    "add_null", fDomain, null);
                                                        }
                                                    })
                                                    .setNegativeButton("No", null)
                                                    .show();
                                        }
                                    });
                                    headerLine.addView(xBtn);

                                    card.addView(headerLine);
                                    card.addView(timestampView);
                                    card.addView(detailsView);

                                    if ("returned".equals(mAction)) {
                                        for (int j = 0; j < messages.length(); j++) {
                                            JSONObject msg = messages.getJSONObject(j);
                                            final String msgTimestamp = msg.optString("timestamp");
                                            TextView msgView = new TextView(MainActivity.this);
                                            msgView.setText(msg.optString("subject"));
                                            msgView.setTextColor(Color.YELLOW);
                                            msgView.setPadding(0, 10, 0, 0);
                                            msgView.setOnClickListener(new View.OnClickListener() {
                                                @Override
                                                public void onClick(View v) {
                                                    performAction(usernameField.getText().toString(),
                                                            passwordField.getText().toString(),
                                                            "display", senderEmail, msgTimestamp);
                                                }
                                            });
                                            card.addView(msgView);
                                        }
                                    }
                                    outputContainer.addView(card);
                                }
                            }
                        }
                    }
                } catch (Exception e) {
                    outputContainer.addView(outputView);
                    outputView.setText("Error parsing data: " + e.getMessage());
                }
            } else {
                outputContainer.addView(outputView);
                outputView.setText(result);
            }

            if (!result.startsWith("Error") && !result.startsWith("Login Failed")) {
                loginLayout.setVisibility(View.GONE);
                isLoggedIn = true;
                menuLayout.setVisibility(View.VISIBLE);
                menuButton.setVisibility(View.VISIBLE);
                if ("display".equals(mAction)) {
                    backButton.setVisibility(View.VISIBLE);
                } else {
                    backButton.setVisibility(View.GONE);
                }
                if ("white".equals(mAction) || "black".equals(mAction) || "null".equals(mAction)
                        || "returned".equals(mAction) || mAction.endsWith("_today")) {
                    navButtonsLayout.setVisibility(View.VISIBLE);
                } else {
                    navButtonsLayout.setVisibility(View.GONE);
                }
                invalidateOptionsMenu();
            }

            if (isBottomRequest) {
                scrollView.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        scrollView.fullScroll(ScrollView.FOCUS_DOWN);
                    }
                }, 100);
            }
        }

    }
}