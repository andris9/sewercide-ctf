<?php
/**
 * Sewercide Plumbing and Co - Website
 */

// Logging helper
function logToSyslog($message) {
    openlog('sewercide-web', LOG_PID | LOG_PERROR, LOG_USER);
    syslog(LOG_INFO, $message);
    closelog();
}

// Get request path
$request_uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

// Simple routing
switch ($request_uri) {
    case '/':
        showHomePage();
        break;
    case '/contact':
        showContactPage();
        break;
    case '/pricing':
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            handlePricingSubmission();
        } else {
            showPricingPage();
        }
        break;
    default:
        http_response_code(404);
        echo "<h1>404 Not Found</h1>";
        break;
}

function getLogo() {
    return '<svg width="200" height="60" viewBox="0 0 200 60" xmlns="http://www.w3.org/2000/svg">
        <!-- Green pipe like Mario -->
        <g transform="translate(5, 10)">
            <!-- Main vertical pipe -->
            <rect x="0" y="0" width="30" height="40" fill="#2d8b3f" stroke="#1a5c29" stroke-width="2" rx="2"/>
            <rect x="3" y="3" width="24" height="34" fill="#3ea854" rx="1"/>

            <!-- Pipe opening (top) -->
            <ellipse cx="15" cy="0" rx="15" ry="5" fill="#1a5c29"/>
            <ellipse cx="15" cy="0" rx="12" ry="4" fill="#2d8b3f"/>
            <ellipse cx="15" cy="0" rx="8" ry="3" fill="#000"/>

            <!-- Pipe rim (bottom) -->
            <rect x="0" y="36" width="30" height="4" fill="#246d35"/>

            <!-- Highlights for 3D effect -->
            <rect x="5" y="8" width="3" height="25" fill="#4fc764" opacity="0.6"/>
        </g>

        <!-- Company name -->
        <text x="45" y="25" font-family="Arial, sans-serif" font-size="20" font-weight="bold" fill="#1e40af">SEWERCIDE</text>
        <text x="45" y="42" font-family="Arial, sans-serif" font-size="12" fill="#6b7280">Plumbing & Co.</text>
    </svg>';
}

function getCommonStyles() {
    return '
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            background-color: #f9fafb;
            min-height: 100vh;
        }
        .max-w-7xl {
            max-width: 1024px;
            margin: 0 auto;
            width: 100%;
        }
        .bg-white {
            background-color: white;
        }
        .shadow {
            box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
        }
        .shadow-lg {
            box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
        }
        .rounded-lg {
            border-radius: 0.5rem;
        }
        .px-4 {
            padding-left: 1rem;
            padding-right: 1rem;
        }
        .py-3 {
            padding-top: 0.75rem;
            padding-bottom: 0.75rem;
        }
        .py-6 {
            padding-top: 1.5rem;
            padding-bottom: 1.5rem;
        }
        .py-8 {
            padding-top: 2rem;
            padding-bottom: 2rem;
        }
        .py-12 {
            padding-top: 3rem;
            padding-bottom: 3rem;
        }
        .px-6 {
            padding-left: 1.5rem;
            padding-right: 1.5rem;
        }
        .px-8 {
            padding-left: 2rem;
            padding-right: 2rem;
        }
        .text-center {
            text-align: center;
        }
        .flex {
            display: flex;
        }
        .items-center {
            align-items: center;
        }
        .justify-between {
            justify-content: space-between;
        }
        .space-x-8 > * + * {
            margin-left: 2rem;
        }

        /* Header */
        .header {
            background: linear-gradient(135deg, #1e40af 0%, #1e3a8a 100%);
            color: white;
        }
        .logo-container {
            background: white;
            padding: 0.5rem 1rem;
            border-radius: 0.5rem;
        }

        /* Alert */
        .alert {
            background-color: #fef3c7;
            border-left: 4px solid #f59e0b;
            color: #92400e;
            padding: 1rem 1.5rem;
        }

        /* Navigation */
        nav {
            background-color: white;
            border-bottom: 1px solid #e5e7eb;
            display: flex;
            gap: 0;
        }
        nav a {
            color: #4b5563;
            text-decoration: none;
            padding: 1rem 1.5rem;
            display: block;
            transition: all 0.2s;
            border-bottom: 2px solid transparent;
            font-weight: 500;
        }
        nav a:hover {
            color: #1e40af;
            background-color: #f9fafb;
        }
        nav a.active {
            color: #1e40af;
            border-bottom-color: #1e40af;
            background-color: #eff6ff;
        }

        /* Typography */
        h1 {
            font-size: 2.25rem;
            font-weight: 700;
            color: #111827;
            margin-bottom: 1.5rem;
        }
        h2 {
            font-size: 1.875rem;
            font-weight: 700;
            color: #111827;
            margin-bottom: 1rem;
        }
        h3 {
            font-size: 1.25rem;
            font-weight: 600;
            color: #374151;
        }

        /* Buttons */
        .btn-primary {
            background-color: #2563eb;
            color: white;
            padding: 0.75rem 2rem;
            border-radius: 0.5rem;
            text-decoration: none;
            display: inline-block;
            font-weight: 600;
            transition: all 0.2s;
            border: none;
            cursor: pointer;
            font-size: 1rem;
        }
        .btn-primary:hover {
            background-color: #1d4ed8;
            transform: translateY(-1px);
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
        }
        .btn-lg {
            padding: 1rem 2.5rem;
            font-size: 1.125rem;
        }

        /* Grid */
        .grid {
            display: grid;
            gap: 1.5rem;
        }
        .grid-cols-2 {
            grid-template-columns: repeat(2, 1fr);
        }
        .grid-cols-4 {
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
        }

        /* Cards */
        .card {
            background: white;
            border-radius: 0.5rem;
            padding: 1.5rem;
            box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1);
            transition: all 0.2s;
        }
        .card:hover {
            box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
            transform: translateY(-2px);
        }
        .card-bordered {
            border: 1px solid #e5e7eb;
        }

        /* Form */
        .form-group {
            margin-bottom: 1.5rem;
        }
        label {
            display: block;
            font-weight: 600;
            color: #374151;
            margin-bottom: 0.5rem;
            font-size: 0.875rem;
            text-transform: uppercase;
            letter-spacing: 0.025em;
        }
        input[type="text"],
        input[type="email"] {
            width: 100%;
            padding: 0.75rem 1rem;
            border: 1px solid #d1d5db;
            border-radius: 0.5rem;
            font-size: 1rem;
            transition: all 0.2s;
            background: white;
        }
        input[type="text"]:focus,
        input[type="email"]:focus {
            outline: none;
            border-color: #2563eb;
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
        }
        input[type="submit"] {
            width: 100%;
            margin-top: 0.5rem;
        }

        /* Hero */
        .hero {
            background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
            color: white;
            padding: 3rem;
            border-radius: 0.75rem;
            margin-bottom: 2rem;
        }
        .hero h2 {
            color: white;
        }

        /* Badge */
        .badge {
            display: inline-block;
            padding: 0.25rem 0.75rem;
            background-color: #dbeafe;
            color: #1e40af;
            border-radius: 9999px;
            font-size: 0.875rem;
            font-weight: 600;
        }

        /* Footer */
        .footer {
            background-color: #1f2937;
            color: #9ca3af;
            padding: 2rem;
            margin-top: 4rem;
        }
        .footer a {
            color: #60a5fa;
            text-decoration: none;
        }
        .footer a:hover {
            text-decoration: underline;
        }

        /* Utilities */
        .mt-2 { margin-top: 0.5rem; }
        .mt-4 { margin-top: 1rem; }
        .mt-6 { margin-top: 1.5rem; }
        .mt-8 { margin-top: 2rem; }
        .mb-2 { margin-bottom: 0.5rem; }
        .mb-4 { margin-bottom: 1rem; }
        .mb-6 { margin-bottom: 1.5rem; }
        .mb-8 { margin-bottom: 2rem; }
        .text-sm { font-size: 0.875rem; }
        .text-lg { font-size: 1.125rem; }
        .text-xl { font-size: 1.25rem; }
        .text-gray-600 { color: #4b5563; }
        .text-gray-700 { color: #374151; }
        .text-blue-600 { color: #2563eb; }
        .font-semibold { font-weight: 600; }
        .font-bold { font-weight: 700; }
        .leading-relaxed { line-height: 1.625; }
    ';
}

function showHomePage() {
    $logo = getLogo();
    $styles = getCommonStyles();
    ?>
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Sewercide Plumbing and Co - Professional Plumbing Services</title>
        <style>
            <?php echo $styles; ?>
        </style>
    </head>
    <body>
        <div class="header py-6">
            <div class="max-w-7xl flex items-center justify-between px-6">
                <div class="logo-container">
                    <?php echo $logo; ?>
                </div>
                <div style="text-align: right;">
                    <div class="text-xl font-bold">24/7 Emergency Service</div>
                    <div class="mt-2 text-sm" style="opacity: 0.9;">Call: (555) 999-0000</div>
                </div>
            </div>
        </div>

        <div class="max-w-7xl px-6 mt-6">
            <div class="alert rounded-lg">
                <strong>⚠️ Notice:</strong> This website is under construction. For questions or suggestions, please contact <strong>webmaster@sewercide.plumbers</strong>
            </div>
        </div>

        <div class="max-w-7xl px-6 mt-6">
            <nav class="rounded-lg shadow">
                <a href="/" class="active">Home</a>
                <a href="/contact">Contact</a>
                <a href="/pricing">Get Quote</a>
            </nav>
        </div>

        <div class="max-w-7xl px-6 py-8">
            <h1>Welcome to Sewercide Plumbing and Co</h1>

            <div class="hero">
                <span class="badge mb-4">Since 2004</span>
                <h2 class="mt-4">Your Trusted Plumbing Partner</h2>
                <p class="text-lg leading-relaxed mt-4">For over 20 years, Sewercide Plumbing has been serving the community with professional, reliable, and affordable plumbing services. We pride ourselves on quick response times, expert technicians, and customer satisfaction guaranteed.</p>
            </div>

            <h2 class="mb-6">Our Services</h2>
            <div class="grid grid-cols-4">
                <div class="card text-center">
                    <div style="font-size: 3rem; margin-bottom: 1rem;">🔧</div>
                    <h3>Emergency Repairs</h3>
                    <p class="text-gray-600 mt-2 text-sm">24/7 emergency plumbing service for urgent issues</p>
                </div>
                <div class="card text-center">
                    <div style="font-size: 3rem; margin-bottom: 1rem;">🚰</div>
                    <h3>Drain Cleaning</h3>
                    <p class="text-gray-600 mt-2 text-sm">Professional drain and sewer line cleaning</p>
                </div>
                <div class="card text-center">
                    <div style="font-size: 3rem; margin-bottom: 1rem;">🔨</div>
                    <h3>Pipe Installation</h3>
                    <p class="text-gray-600 mt-2 text-sm">Expert pipe installation and replacement</p>
                </div>
                <div class="card text-center">
                    <div style="font-size: 3rem; margin-bottom: 1rem;">♨️</div>
                    <h3>Water Heaters</h3>
                    <p class="text-gray-600 mt-2 text-sm">Water heater installation and repair</p>
                </div>
            </div>

            <div class="text-center mt-8">
                <a href="/pricing" class="btn-primary btn-lg">Get Your Free Quote Today</a>
            </div>
        </div>

        <div class="footer text-center">
            <p>&copy; 2024 Sewercide Plumbing and Co. All rights reserved.</p>
            <p class="mt-2"><a href="https://sewercide.plumbers">www.sewercide.plumbers</a> | Email: <a href="mailto:info@sewercide.plumbers">info@sewercide.plumbers</a></p>
        </div>
    </body>
    </html>
    <?php
}

function showContactPage() {
    $logo = getLogo();
    $styles = getCommonStyles();
    ?>
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Contact Us - Sewercide Plumbing</title>
        <style>
            <?php echo $styles; ?>
        </style>
    </head>
    <body>
        <div class="header py-6">
            <div class="max-w-7xl flex items-center justify-between px-6">
                <div class="logo-container">
                    <?php echo $logo; ?>
                </div>
                <div style="text-align: right;">
                    <div class="text-xl font-bold">24/7 Emergency Service</div>
                    <div class="mt-2 text-sm" style="opacity: 0.9;">Call: (555) 999-0000</div>
                </div>
            </div>
        </div>

        <div class="max-w-7xl px-6 mt-6">
            <div class="alert rounded-lg">
                <strong>⚠️ Notice:</strong> This website is under construction. For questions or suggestions, please contact <strong>webmaster@sewercide.plumbers</strong>
            </div>
        </div>

        <div class="max-w-7xl px-6 mt-6">
            <nav class="rounded-lg shadow">
                <a href="/">Home</a>
                <a href="/contact" class="active">Contact</a>
                <a href="/pricing">Get Quote</a>
            </nav>
        </div>

        <div class="max-w-7xl px-6 py-8">
            <h1>Contact Our Team</h1>

            <div class="grid grid-cols-2 mb-8">
                <div class="card card-bordered">
                    <div class="badge mb-2">Chief Executive Officer</div>
                    <h3 class="mt-2">John Smith</h3>
                    <p class="text-gray-600 mt-2 text-sm">jsmith@sewercide.plumbers</p>
                </div>
                <div class="card card-bordered">
                    <div class="badge mb-2">Chief Financial Officer</div>
                    <h3 class="mt-2">Sarah Johnson</h3>
                    <p class="text-gray-600 mt-2 text-sm">sjohnson@sewercide.plumbers</p>
                </div>
                <div class="card card-bordered">
                    <div class="badge mb-2">Head Plumber</div>
                    <h3 class="mt-2">Mario Mätas</h3>
                    <p class="text-gray-600 mt-2 text-sm">mmatas@sewercide.plumbers</p>
                </div>
                <div class="card card-bordered">
                    <div class="badge mb-2">Senior Plumber</div>
                    <h3 class="mt-2">Luigi Rästas</h3>
                    <p class="text-gray-600 mt-2 text-sm">lrastas@sewercide.plumbers</p>
                </div>
            </div>

            <div class="card" style="background-color: #f9fafb;">
                <h2>Contact Information</h2>
                <div class="text-gray-700 mt-4 text-sm">
                    <p class="mb-2"><strong>Office Phone:</strong> (555) 123-4567</p>
                    <p class="mb-2"><strong>Emergency Hotline:</strong> (555) 999-0000</p>
                    <p class="mb-2"><strong>Email:</strong> info@sewercide.plumbers</p>
                    <p class="mb-2"><strong>Website:</strong> <a href="https://sewercide.plumbers" class="text-blue-600">www.sewercide.plumbers</a></p>
                    <p class="mb-2"><strong>Address:</strong> 123 Pipe Street, Plumbingville, PL 12345</p>
                </div>
            </div>
        </div>

        <div class="footer text-center">
            <p>&copy; 2024 Sewercide Plumbing and Co. All rights reserved.</p>
            <p class="mt-2"><a href="https://sewercide.plumbers">www.sewercide.plumbers</a> | Email: <a href="mailto:info@sewercide.plumbers">info@sewercide.plumbers</a></p>
        </div>
    </body>
    </html>
    <?php
}

function showPricingPage() {
    $logo = getLogo();
    $styles = getCommonStyles();
    ?>
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Get Quote - Sewercide Plumbing</title>
        <style>
            <?php echo $styles; ?>
        </style>
    </head>
    <body>
        <div class="header py-6">
            <div class="max-w-7xl flex items-center justify-between px-6">
                <div class="logo-container">
                    <?php echo $logo; ?>
                </div>
                <div style="text-align: right;">
                    <div class="text-xl font-bold">24/7 Emergency Service</div>
                    <div class="mt-2 text-sm" style="opacity: 0.9;">Call: (555) 999-0000</div>
                </div>
            </div>
        </div>

        <div class="max-w-7xl px-6 mt-6">
            <div class="alert rounded-lg">
                <strong>⚠️ Notice:</strong> This website is under construction. For questions or suggestions, please contact <strong>webmaster@sewercide.plumbers</strong>
            </div>
        </div>

        <div class="max-w-7xl px-6 mt-6">
            <nav class="rounded-lg shadow">
                <a href="/">Home</a>
                <a href="/contact">Contact</a>
                <a href="/pricing" class="active">Get Quote</a>
            </nav>
        </div>

        <div class="max-w-7xl px-6 py-8">
            <h1>Get Your Personalized Quote</h1>

            <div class="card mb-6" style="background-color: #eff6ff; border-left: 4px solid #2563eb;">
                <p class="font-semibold mb-2">Get a customized quote instantly!</p>
                <p class="text-gray-700 text-sm">Fill out the form below and receive a personalized pricing document tailored to your plumbing needs. Our competitive rates and transparent pricing ensure you get the best value for your investment.</p>
            </div>

            <div class="card shadow-lg">
                <form method="POST" action="/pricing" style="max-width: 600px; margin: 0 auto;">
                    <div class="form-group">
                        <label for="name">Your Full Name</label>
                        <input type="text" id="name" name="name" placeholder="Enter your name" required>
                    </div>
                    <div class="form-group">
                        <label for="email">Your Email Address</label>
                        <input type="email" id="email" name="email" placeholder="your.email@example.com" required>
                    </div>
                    <input type="submit" value="Get a Quote" class="btn-primary">
                </form>
            </div>

            <div class="grid grid-cols-4 mt-8" style="grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));">
                <div class="card text-center card-bordered">
                    <div style="font-size: 2rem; color: #10b981; margin-bottom: 0.5rem;">✓</div>
                    <p class="text-sm font-semibold text-gray-700">Competitive Pricing</p>
                </div>
                <div class="card text-center card-bordered">
                    <div style="font-size: 2rem; color: #10b981; margin-bottom: 0.5rem;">✓</div>
                    <p class="text-sm font-semibold text-gray-700">No Obligation Quote</p>
                </div>
                <div class="card text-center card-bordered">
                    <div style="font-size: 2rem; color: #10b981; margin-bottom: 0.5rem;">✓</div>
                    <p class="text-sm font-semibold text-gray-700">Free Consultation</p>
                </div>
            </div>
        </div>

        <div class="footer text-center">
            <p>&copy; 2024 Sewercide Plumbing and Co. All rights reserved.</p>
            <p class="mt-2"><a href="https://sewercide.plumbers">www.sewercide.plumbers</a> | Email: <a href="mailto:info@sewercide.plumbers">info@sewercide.plumbers</a></p>
        </div>
    </body>
    </html>
    <?php
}

function handlePricingSubmission() {
    // Get raw input
    $name_raw = $_POST['name'] ?? '';
    $email_raw = $_POST['email'] ?? '';

    // Sanitize name (remove control characters and newlines)
    $name = preg_replace('/[\x00-\x1F\x7F]/', '', $name_raw);
    $name = trim($name);

    if (empty($name)) {
        die("Error: Invalid name provided.");
    }

    // Email filtering - remove dangerous shell metacharacters
    $email = $email_raw;

    // Remove potentially problematic characters
    $email_escaped = str_replace([';', '|', '&', '`', '$', '>', '<', "\n", "\r", "\t"], '', $email);

    // Whitelist check - only allow valid email characters
    if (!preg_match('/^[A-Za-z0-9@._+\-\/: ]+$/', $email)) {
        logToSyslog("Pricing request REJECTED - invalid email format from " . $_SERVER['REMOTE_ADDR']);
        die("Error: Email contains invalid characters.");
    }

    if (empty($email)) {
        die("Error: Invalid email provided.");
    }

    // Sanitize and secure
    $name_escaped = escapeshellarg($name);

    // Log the submission
    $client_ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
    logToSyslog(sprintf(
        "Pricing request: IP=%s, Name='%s', Email='%s'",
        $client_ip,
        $name,
        $email
    ));

    // Call the shell script to generate PDF
    $script_path = '/var/www/sewercide/generate-personal-pricing.sh';
    $template_path = '/var/www/sewercide/pricing-template.pdf';

    

    // Build command
    $cmd = sprintf(
        '%s %s %s %s 2>&1',
        escapeshellarg($script_path),
        $name_escaped,
        $email_escaped,
        escapeshellarg($template_path)
    );

    logToSyslog("Executing: $cmd");

    // Execute and capture output
    exec($cmd, $output, $return_code);

    if ($return_code !== 0) {
        logToSyslog("Script execution failed with code $return_code: " . implode("\n", $output));
        die("Error: Failed to generate pricing PDF. Please try again later.");
    }

    // Get the filename from script output (first line)
    $pdf_filename = trim($output[0] ?? '');

    if (empty($pdf_filename)) {
        logToSyslog("Script did not return filename");
        die("Error: Failed to generate pricing PDF. Please try again later.");
    }

    // Redirect to generated PDF
    header("Location: /static/$pdf_filename", true, 302);
    exit;
}
