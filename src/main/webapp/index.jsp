<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
<title>dushyant@portfolio: ~</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:ital,wght@0,400;0,500;0,700;0,800;1,400&display=swap');

  :root{
    --bg:        #060a07;
    --bg-raised: #0b120c;
    --green:     #39ff8a;
    --green-dim: #1e8a4c;
    --green-dark:#0f4a29;
    --amber:     #ffb454;
    --text:      #c9f5d9;
    --text-dim:  #5f8f74;
    --red:       #ff5f56;
    --yellow:    #ffbd2e;
    --border:    #163524;
  }

  *{ box-sizing:border-box; }

  html{ scroll-behavior:smooth; overflow-x:hidden; }

  body{
    margin:0;
    background:
      radial-gradient(ellipse at 50% 0%, #0a140d 0%, var(--bg) 60%);
    color:var(--text);
    font-family:'JetBrains Mono', monospace;
    font-size:15px;
    line-height:1.6;
    min-height:100vh;
    padding:28px 16px 80px;
  }

  /* CRT scanline + vignette overlay */
  body::before{
    content:"";
    position:fixed; inset:0;
    background:repeating-linear-gradient(
      to bottom,
      rgba(255,255,255,0.018) 0px,
      rgba(255,255,255,0.018) 1px,
      transparent 1px,
      transparent 3px
    );
    pointer-events:none;
    z-index:50;
  }
  body::after{
    content:"";
    position:fixed; inset:0;
    box-shadow: inset 0 0 180px rgba(0,0,0,0.75);
    pointer-events:none;
    z-index:51;
  }

  .term{
    max-width:900px;
    width:100%;
    margin:0 auto;
    background:var(--bg-raised);
    border:1px solid var(--border);
    border-radius:10px;
    box-shadow:0 0 0 1px rgba(57,255,138,0.04), 0 30px 80px -20px rgba(0,0,0,0.8), 0 0 40px -10px rgba(57,255,138,0.06);
    overflow:hidden;
  }

  .titlebar{
    display:flex;
    align-items:center;
    gap:10px;
    padding:11px 14px;
    background:linear-gradient(180deg,#0e1710,#0a120c);
    border-bottom:1px solid var(--border);
  }
  .dot{ width:11px; height:11px; border-radius:50%; }
  .dot.r{ background:var(--red); }
  .dot.y{ background:var(--yellow); }
  .dot.g{ background:var(--green-dim); }
  .titlebar span.path{
    margin:0 auto;
    color:var(--text-dim);
    font-size:12.5px;
    letter-spacing:.03em;
  }

  .screen{
    padding:26px 26px 10px;
  }

  .banner{
    color:var(--green);
    font-size:clamp(20px,5vw,34px);
    font-weight:800;
    letter-spacing:.06em;
    margin:0 0 4px;
    text-shadow:0 0 10px rgba(57,255,138,0.35);
    white-space:normal;
    word-break:break-word;
  }
  .cursor2{ animation:blink 1s steps(1) infinite; }

  .subtitle{
    color:var(--text-dim);
    margin:0 0 26px;
    font-size:13px;
  }
  .subtitle .amber{ color:var(--amber); }

  .line{ display:flex; gap:10px; flex-wrap:wrap; margin:22px 0 10px; }
  .prompt{ color:var(--green); white-space:nowrap; }
  .prompt .user{ color:var(--amber); }
  .cmd{ color:#eaffef; font-weight:600; }

  .output{ margin:2px 0 0 0; color:var(--text); }
  .output p{ margin:6px 0; }
  .dim{ color:var(--text-dim); }
  .amber{ color:var(--amber); }
  .green{ color:var(--green); }

  .kv{ display:grid; grid-template-columns:130px 1fr; gap:4px 12px; margin:8px 0 4px; }
  .kv dt{ color:var(--text-dim); }
  .kv dd{ margin:0; }
  .kv a{ color:var(--green); text-decoration:none; border-bottom:1px dashed var(--green-dark); }
  .kv a:hover{ color:var(--amber); border-color:var(--amber); }

  ul.plain{ list-style:none; padding-left:0; margin:8px 0; }
  ul.plain li::before{ content:"> "; color:var(--green-dim); }

  .grid{
    display:grid;
    grid-template-columns:repeat(auto-fit,minmax(220px,1fr));
    gap:10px 22px;
    margin:10px 0;
  }
  .grid .cat{ color:var(--amber); }
  .grid .items{ color:var(--text); }

  table{
    width:100%;
    border-collapse:collapse;
    margin:10px 0 4px;
    font-size:13.5px;
  }
  th,td{
    text-align:left;
    padding:7px 10px 7px 0;
    border-bottom:1px solid var(--border);
  }
  th{ color:var(--amber); font-weight:600; }
  td{ color:var(--text); }
  td.cat{ color:var(--green); white-space:nowrap; }

  .proj{
    border-left:2px solid var(--green-dark);
    padding:2px 0 10px 14px;
    margin:14px 0;
  }
  .proj h4{ margin:0 0 4px; color:var(--green); font-size:14px; }
  .proj p{ margin:3px 0; color:var(--text); font-size:13.5px; }
  .proj .tag{ color:var(--text-dim); font-size:12px; }

  .timeline{ margin:10px 0; }
  .tl-year{
    display:flex; gap:14px; margin:16px 0;
  }
  .tl-year .yr{
    color:var(--amber);
    min-width:52px;
    font-weight:700;
  }
  .tl-year .body p{ margin:0 0 3px; color:var(--text); font-size:13.5px; }
  .tl-year .body p.head{ color:var(--green); font-size:14px; margin-bottom:5px; }

  .badges{ display:flex; flex-wrap:wrap; gap:8px; margin:10px 0; }
  .badge{
    border:1px solid var(--border);
    background:rgba(57,255,138,0.04);
    color:var(--text);
    padding:5px 10px;
    border-radius:5px;
    font-size:12.5px;
  }
  .badge::before{ content:"[x] "; color:var(--green); }

  .social{ display:flex; flex-wrap:wrap; gap:10px 22px; margin:10px 0; }
  .social a{
    color:var(--text);
    text-decoration:none;
    border-bottom:1px solid var(--border);
    padding-bottom:1px;
    font-size:13.5px;
  }
  .social a:hover{ color:var(--green); border-color:var(--green); }
  .social a .key{ color:var(--green-dim); }

  hr.rule{
    border:none;
    border-top:1px dashed var(--border);
    margin:26px 0;
  }

  /* live input line */
  .inputline{
    display:flex;
    align-items:center;
    gap:10px;
    padding:16px 26px 24px;
    border-top:1px solid var(--border);
    background:linear-gradient(180deg, rgba(57,255,138,0.015), transparent);
  }
  .inputline .prompt{ flex:none; }
  .inputline input{
    flex:1;
    background:transparent;
    border:none;
    outline:none;
    color:#eaffef;
    font-family:inherit;
    font-size:15px;
    caret-color:var(--green);
  }
  .cursor{
    display:inline-block;
    width:8px; height:16px;
    background:var(--green);
    margin-left:2px;
    animation:blink 1s steps(1) infinite;
    vertical-align:middle;
    box-shadow:0 0 6px var(--green);
  }
  @keyframes blink{ 50%{ opacity:0; } }

  .hint{
    color:var(--text-dim);
    font-size:12px;
    padding:0 26px 20px;
    margin-top:-6px;
  }
  .hint kbd{
    background:var(--bg);
    border:1px solid var(--border);
    padding:1px 6px;
    border-radius:4px;
    color:var(--green);
    font-size:11px;
  }

  a.link{ color:var(--green); }

  ::selection{ background:var(--green-dark); color:#eaffef; }

  @media (max-width:600px){
    body{ padding:14px 8px 60px; font-size:13.5px; }
    .screen{ padding:18px 16px 6px; }
    .kv{ grid-template-columns:100px 1fr; }
    .inputline{ padding:14px 16px 20px; }
    .tl-year{ flex-direction:column; gap:2px; }
    .titlebar span.path{ max-width:60vw; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
    table{ display:block; overflow-x:auto; }
  }
  @media (max-width:380px){
    .banner{ font-size:18px; }
    .kv{ grid-template-columns:1fr; }
    .kv dt{ margin-top:6px; }
    .grid{ grid-template-columns:1fr; }
  }

  @media (prefers-reduced-motion: reduce){
    .cursor{ animation:none; }
    html{ scroll-behavior:auto; }
  }
</style>
</head>
<body>

<div class="term" id="term">
  <div class="titlebar">
    <span class="dot r"></span><span class="dot y"></span><span class="dot g"></span>
    <span class="path">guest@portfolio: ~/dushyant-sharma</span>
  </div>

  <div class="screen" id="screen">

<div class="banner">DUSHYANT SHARMA<span class="cursor2">_</span></div>
    <p class="subtitle">Cloud &amp; DevOps Engineer <span class="amber">-</span> SRE Enthusiast <span class="amber">-</span> booted in 0.24s <span class="amber">-</span> type <b>help</b> below to explore</p>

    <!-- whoami -->
    <div class="line"><span class="prompt"><span class="user">guest@portfolio</span>:~$</span><span class="cmd">whoami</span></div>
    <div class="output">
      <p>Dushyant Sharma  -  Cloud / DevOps / SRE Engineer, based in India (remote friendly).</p>
      <p class="dim">Automating infrastructure, building resilient pipelines, and contributing to open source. Coder by day, hacker by night.</p>
      <dl class="kv">
        <dt>email</dt><dd><a href="mailto:227dushyantsharma@gmail.com">227dushyantsharma@gmail.com</a></dd>
        <dt>location</dt><dd>India (Remote Friendly)</dd>
        <dt>resume</dt><dd><a href="https://drive.google.com/uc?export=download&id=1OiWPRT7k8Dnv49D2T8Mux3J6Mir9kT1D">resume.pdf (down) download</a></dd>
      </dl>
    </div>

    <!-- cat focus.txt -->
    <div class="line"><span class="prompt"><span class="user">guest@portfolio</span>:~$</span><span class="cmd">cat focus.txt</span></div>
    <div class="output">
      <ul class="plain">
        <li>Automating everything  -  CI/CD, infrastructure, monitoring</li>
        <li>Hands-on with AWS, GCP, Azure, Docker, Kubernetes, Terraform</li>
        <li>Obsessed with scalability, SRE practice, and zero-downtime deploys</li>
        <li>Currently learning Go, Rust, service mesh, GitOps</li>
        <li>Exploring cloud security and FinOps</li>
      </ul>
    </div>

    <!-- skills --all -->
    <div class="line"><span class="prompt"><span class="user">guest@portfolio</span>:~$</span><span class="cmd">skills --all</span></div>
    <div class="output">
      <div class="grid">
        <div><div class="cat"> cloud platforms</div><div class="items">AWS - GCP - Azure</div></div>
        <div><div class="cat"> devops tools</div><div class="items">Docker - Kubernetes - Terraform - Jenkins - GitHub Actions</div></div>
        <div><div class="cat"> monitoring / sre</div><div class="items">CloudWatch - Prometheus - Grafana - Netdata - Splunk - Dynatrace</div></div>
        <div><div class="cat"> programming</div><div class="items">Python - Java - Shell - R</div></div>
        <div><div class="cat"> web / frontend</div><div class="items">React - Firebase - HTML - CSS</div></div>
        <div><div class="cat"> security basics</div><div class="items">IAM - GCP Security - Palo Alto Academy Labs</div></div>
      </div>
    </div>

    <!-- ls projects/ -->
    <div class="line"><span class="prompt"><span class="user">guest@portfolio</span>:~$</span><span class="cmd">ls projects/ -l</span></div>
    <div class="output">
      <div class="proj">
        <h4> AgroChain  -  Blockchain-Powered Marketplace</h4>
        <p>Smart-contract-enabled marketplace connecting farmers, lenders, and consumers directly, cutting out middlemen.</p>
        <p>Predictive-analytics module built on Firebase &amp; Solidity to forecast crop demand and pricing.</p>
        <p class="tag">stack: solidity - firebase - react</p>
      </div>
      <div class="proj">
        <h4> Bank Management System</h4>
        <p>Full web banking app: account management, live transactions, and a dedicated admin control panel for oversight.</p>
        <p>Built to demonstrate secure CRUD flows and role-based access on top of Firebase auth.</p>
        <p class="tag">stack: react - firebase</p>
      </div>
      <div class="proj">
        <h4> AWS / GCP Monitoring Setup</h4>
        <p>Real-time observability stack with Netdata and CloudWatch, plus alerting and dashboards for infra health.</p>
        <p class="tag">stack: aws - gcp - netdata - cloudwatch</p>
      </div>
      <div class="proj">
        <h4> <a class="link" href="https://github.com/Dushyantsharmma/Netdata-Monitoring-with-Docker" target="_blank" rel="noopener">Netdata Monitoring with Docker</a></h4>
        <p>Real-time system dashboard (CPU, memory, disk, network) via Netdata running in Docker on WSL.</p>
        <p class="tag">stack: docker - netdata - linux</p>
      </div>
      <div class="proj">
        <h4> <a class="link" href="https://github.com/Dushyantsharmma/Jenkins-Zero-To-Hero" target="_blank" rel="noopener">Jenkins Zero To Hero</a></h4>
        <p>Jenkins CI/CD setup with Docker as a build agent, deploying to Kubernetes via Argo CD (GitOps).</p>
        <p class="tag">stack: jenkins - docker - k8s - argo cd</p>
      </div>
      <div class="proj">
        <h4> <a class="link" href="https://github.com/Dushyantsharmma/terraform-zero-to-hero" target="_blank" rel="noopener">Terraform Zero To Hero</a></h4>
        <p>Hands-on Terraform fundamentals through advanced IaC patterns.</p>
        <p class="tag">stack: terraform - hcl</p>
      </div>
    </div>
    <p class="dim" style="margin:10px 0 0;">-> <a class="link" href="https://github.com/Dushyantsharmma?tab=repositories" target="_blank" rel="noopener">view all repos on GitHub</a></p>

    <!-- certs --list -->
    <div class="line"><span class="prompt"><span class="user">guest@portfolio</span>:~$</span><span class="cmd">certs --list</span></div>
    <div class="output">
      <div class="badges">
        <span class="badge"><a class="link" href="https://www.cloudskillsboost.google/public_profiles/c4374c70-f738-4169-9231-67712627075a" target="_blank" rel="noopener" style="color:inherit;text-decoration:none;">Google Cloud Skills Boost</a></span>
        <span class="badge"><a class="link" href="https://www.credly.com/users/dushyant-sharma.c2136780/" target="_blank" rel="noopener" style="color:inherit;text-decoration:none;">Credly Certifications</a></span>
        <span class="badge">AWS Academy Cloud Foundations</span>
        <span class="badge">NPTEL  -  Cloud Computing (IIT Kharagpur)</span>
        <span class="badge">Palo Alto Cloud Security Engineer</span>
      </div>
    </div>

    <!-- log --graph timeline -->
    <div class="line"><span class="prompt"><span class="user">guest@portfolio</span>:~$</span><span class="cmd">log --graph --timeline</span></div>
    <div class="output timeline">
      <div class="tl-year">
        <div class="yr">2021</div>
        <div class="body">
          <p class="head">Started B.E. in Cloud Computing @ Chandigarh University</p>
          <p>Foundation in CS fundamentals - first exposure to cloud concepts</p>
        </div>
      </div>
      <div class="tl-year">
        <div class="yr">2022</div>
        <div class="body">
          <p class="head">Programming &amp; web development</p>
          <p>Java, OOPs, DSA - built static and dynamic websites</p>
        </div>
      </div>
      <div class="tl-year">
        <div class="yr">2023</div>
        <div class="body">
          <p class="head">Google Cloud Bootcamp &amp; real projects</p>
          <p>Built AgroChain on blockchain &amp; Firebase - completed the 8-week Google Cloud Bootcamp by GeeksforGeeks</p>
        </div>
      </div>
      <div class="tl-year">
        <div class="yr">2024</div>
        <div class="body">
          <p class="head">DevOps &amp; infrastructure mastery</p>
          <p>Terraform, Docker, Kubernetes, CI/CD - monitoring with Prometheus &amp; Grafana - beginner -> intermediate MLOps</p>
        </div>
      </div>
      <div class="tl-year">
        <div class="yr">2025</div>
        <div class="body">
          <p class="head">Internship &amp; cloud automation</p>
          <p>DevOps Intern @ Elevate Labs (May-Jun 2025) - GitHub Actions, Docker, Linux &amp; AWS</p>
        </div>
      </div>
    </div>

    <!-- contact --show -->
    <div class="line"><span class="prompt"><span class="user">guest@portfolio</span>:~$</span><span class="cmd">contact --show</span></div>
    <div class="output">
      <div class="social">
        <a href="mailto:227dushyantsharma@gmail.com"><span class="key">mail</span> 227dushyantsharma@gmail.com</a>
        <a href="https://linkedin.com/in/dushyant-sharma-3619b420b/" target="_blank" rel="noopener"><span class="key">linkedin</span> /dushyant-sharma</a>
        <a href="https://github.com/dushyantsharmma" target="_blank" rel="noopener"><span class="key">github</span> /dushyantsharmma</a>
        <a href="https://instagram.com/dushyantshharmaa_" target="_blank" rel="noopener"><span class="key">instagram</span> @dushyantshharmaa_</a>
        <a href="https://x.com/Dushyantsharmaq" target="_blank" rel="noopener"><span class="key">x</span> @Dushyantsharmaq</a>
        <a href="https://www.facebook.com/dushyanat.sharma/" target="_blank" rel="noopener"><span class="key">facebook</span> dushyanat.sharma</a>
        <a href="https://www.credly.com/users/dushyant-sharma.c2136780/" target="_blank" rel="noopener"><span class="key">credly</span> badges</a>
        <a href="https://www.cloudskillsboost.google/public_profiles/c4374c70-f738-4169-9231-67712627075a" target="_blank" rel="noopener"><span class="key">gcloud</span> skills profile</a>
        <a href="https://drive.google.com/uc?export=download&id=1OiWPRT7k8Dnv49D2T8Mux3J6Mir9kT1D" ><span class="key">resume</span> download (down)</a>
      </div>
    </div>

    <!-- stats --github -->
    <div class="line"><span class="prompt"><span class="user">guest@portfolio</span>:~$</span><span class="cmd">stats --github</span></div>
    <div class="output">
      <p><img src="https://github-readme-stats.vercel.app/api?username=Dushyantsharmma&show_icons=true&theme=tokyonight&hide_border=true&bg_color=00000000" alt="GitHub stats" style="max-width:100%;height:auto;" onerror="this.outerHTML='<span class=\'dim\'>stats card unavailable - </span><a class=\'link\' href=\'https://github.com/Dushyantsharmma\' target=\'_blank\'>view on GitHub</a>'"></p>
      <p><img src="https://github-readme-streak-stats.herokuapp.com/?user=Dushyantsharmma&theme=tokyonight&hide_border=true&background=00000000" alt="Streak stats" style="max-width:100%;height:auto;" onerror="this.remove()"></p>
      <p><img src="https://github-readme-stats.vercel.app/api/top-langs/?username=Dushyantsharmma&layout=compact&theme=tokyonight&hide_border=true&bg_color=00000000" alt="Top languages" style="max-width:100%;height:auto;" onerror="this.remove()"></p>
      <p><img src="https://github-profile-trophy.vercel.app/?username=Dushyantsharmma&theme=algolia&margin-w=8&margin-h=8&no-bg=true&no-frame=true" alt="Trophies" style="max-width:100%;height:auto;" onerror="this.remove()"></p>
      <p class="dim">(images load from GitHub's live badge services - if any fail to render, <a class="link" href="https://github.com/Dushyantsharmma" target="_blank">see live stats on GitHub</a>)</p>
    </div>

    <!-- tools --modern -->
    <div class="line"><span class="prompt"><span class="user">guest@portfolio</span>:~$</span><span class="cmd">tools --modern</span></div>
    <div class="output">
      <div class="grid">
        <div><div class="cat"> cluster ops</div><div class="items">K9s - Lens - Helm - Kustomize</div></div>
        <div><div class="cat"> gitops / cd</div><div class="items">Argo CD - Flux</div></div>
        <div><div class="cat"> iac</div><div class="items">Terraform - Terragrunt - Pulumi</div></div>
        <div><div class="cat"> service mesh</div><div class="items">Istio - Linkerd</div></div>
        <div><div class="cat"> observability</div><div class="items">Grafana - Prometheus - Loki - OpenTelemetry</div></div>
        <div><div class="cat"> secrets/sec</div><div class="items">Vault - Trivy - SOPS</div></div>
      </div>
    </div>

    <hr class="rule">
    <p class="dim" style="margin:0 0 20px;">"Code. Break. Fix. Learn. Repeat." <span class="amber"> - </span> Dushyant Sharma</p>

  </div>

  <div class="inputline">
    <span class="prompt"><span class="user">guest@portfolio</span>:~$</span>
    <input id="cmdInput" type="text" autocomplete="off" spellcheck="false" placeholder="type a command...">
    <span class="cursor"></span>
  </div>
  <p class="hint">try <kbd>whoami</kbd> - <kbd>projects</kbd> - <kbd>stats</kbd> - <kbd>tools</kbd> - <kbd>resume</kbd> - <kbd>uptime</kbd> - <kbd>neofetch</kbd> - <kbd>joke</kbd> - <kbd>contact</kbd>  -  <kbd>UpDown</kbd> history, <kbd>Tab</kbd> autocomplete</p>
</div>

<script> const screen = document.getElementById('screen');
  const input  = document.getElementById('cmdInput');
  const term   = document.getElementById('term');

  const bootTime = Date.now();
  const jokes = [
    "Why do DevOps engineers love nature? It has great uptime.",
    "There's no place like 127.0.0.1.",
    "I'd tell you a Kubernetes joke but it needs 3 replicas to land.",
    "My code doesn't have bugs, it has undocumented features.",
    "Terraform apply  -  the closest thing to a leap of faith in this job."
  ];

  const responses = {
    help: `Commands: whoami, about, skills, projects, certs, timeline, stats, tools, contact, resume, social, github, uptime, neofetch, joke, matrix, coffee, sudo whoami, clear`,
    whoami: `Dushyant Sharma  -  Cloud/DevOps/SRE engineer based in India, remote friendly. Automating infra, writing resilient pipelines, contributing to open source.`,
    about: `Dushyant Sharma  -  Cloud/DevOps/SRE engineer based in India, remote friendly. Automating infra, writing resilient pipelines, contributing to open source.`,
    skills: `Cloud: AWS - GCP - Azure  |  DevOps: Docker - Kubernetes - Terraform - Jenkins - GitHub Actions  |  Monitoring: CloudWatch - Prometheus - Grafana  |  Code: Python - Java - Shell - R`,
    projects: `AgroChain - Bank Management System - AWS/GCP Monitoring Setup - <a class="link" href="https://github.com/Dushyantsharmma/Netdata-Monitoring-with-Docker" target="_blank">Netdata-Monitoring-with-Docker</a> - <a class="link" href="https://github.com/Dushyantsharmma/Jenkins-Zero-To-Hero" target="_blank">Jenkins-Zero-To-Hero</a> - <a class="link" href="https://github.com/Dushyantsharmma/terraform-zero-to-hero" target="_blank">terraform-zero-to-hero</a>  -  full list on <a class="link" href="https://github.com/Dushyantsharmma?tab=repositories" target="_blank">GitHub</a>`,
    certs: `Google Cloud Skills Boost - AWS Academy Cloud Foundations - NPTEL Cloud Computing (IIT Kharagpur) - Palo Alto Cloud Security Engineer`,
    timeline: `2021 Chandigarh University -> 2022 Programming fundamentals -> 2023 Google Cloud Bootcamp + AgroChain -> 2024 DevOps mastery -> 2025 DevOps Intern @ Elevate Labs`,
    resume: `Downloading resume.pdf...`,
    social: `github.com/Dushyantsharmma - linkedin.com/in/dushyant-sharma-3619b420b - instagram @dushyantshharmaa_ - x @Dushyantsharmaq`,
    contact: `Reach me at 227dushyantsharma@gmail.com, on <a class="link" href="https://linkedin.com/in/dushyant-sharma-3619b420b/" target="_blank">LinkedIn</a>, or scroll up for GitHub / Instagram / X / Credly links.`,
    github: `Opening GitHub profile...`,
    stats: `Scroll up to the <b>stats --github</b> block for live GitHub stats, streak, top languages, and trophies.`,
    tools: `Scroll up to <b>tools --modern</b> for the current DevOps toolbelt: K9s, Argo CD, Terragrunt, Istio, Vault, and more.`,
    coffee: ` brewing... done. Caffeine level: optimal. Resuming deployment.`,
    matrix: `Wake up, Neo... the pipeline has you. `,
  };

  function appendLine(cmdText){
    const line = document.createElement('div');
    line.className = 'line';
    line.innerHTML = `<span class="prompt"><span class="user">guest@portfolio</span>:~$</span><span class="cmd"></span>`;
    line.querySelector('.cmd').textContent = cmdText;
    screen.insertBefore(line, screen.lastElementChild.nextSibling);
    return line;
  }

  function appendOutput(html){
    const out = document.createElement('div');
    out.className = 'output';
    out.innerHTML = `<p>${html}</p>`;
    screen.appendChild(out);
  }

  function handleCommand(raw){
    const cmd = raw.trim();
    if(!cmd) return;
    appendLine(cmd);
    const key = cmd.toLowerCase();

    if(key === 'clear'){
      document.querySelectorAll('#screen > .line, #screen > .output').forEach((el,i) => {
        if(i >= 0) el.remove();
      });
      return;
    }
    if(key === 'sudo whoami'){
      appendOutput(`<span class="amber">guest is not in the sudoers file. This incident will be reported.</span> <span class="dim">(just kidding  -  it's still Dushyant.)</span>`);
    } else if(key === 'sudo rm -rf /' || key === 'sudo rm -rf /*'){
      appendOutput(`<span class="amber">Nice try </span> deleting production is a rite of passage, not a feature. Nothing was harmed.`);
    } else if(key === 'resume'){
      appendOutput(responses.resume);
      const a = document.createElement('a');
      a.href = 'https://drive.google.com/uc?export=download&id=1OiWPRT7k8Dnv49D2T8Mux3J6Mir9kT1D';
      a.click();
    } else if(key === 'github'){
      appendOutput(responses.github);
      window.open('https://github.com/Dushyantsharmma', '_blank');
    } else if(key === 'uptime'){
      const s = Math.floor((Date.now() - bootTime) / 1000);
      appendOutput(`up ${s}s - guest sessions: 1 - load average: 0.42, 0.13, 0.07 <span class="dim">(all green, all good)</span>`);
    } else if(key === 'neofetch'){
      appendOutput(`<span class="green">guest@portfolio</span><br>OS: DushyantOS (Cloud Edition)<br>Uptime: ${Math.floor((Date.now()-bootTime)/1000)}s<br>Shell: dushyant-sh<br>CPU: Coffee-powered <br>Memory: 99% ideas, 1% sleep`);
    } else if(key === 'joke'){
      appendOutput(jokes[Math.floor(Math.random()*jokes.length)]);
    } else if(responses[key]){
      appendOutput(responses[key]);
    } else {
      appendOutput(`<span class="dim">command not found:</span> ${cmd} <span class="dim"> -  type</span> help`);
    }
    window.scrollTo({ top: document.body.scrollHeight, behavior:'smooth' });
  }

  const cmdList = Object.keys(responses).concat(['sudo whoami','clear','uptime','neofetch','joke']);
  let history = [];
  let hIndex = -1;

  input.addEventListener('keydown', (e) => {
    if(e.key === 'Enter'){
      if(input.value.trim()){ history.push(input.value.trim()); }
      hIndex = history.length;
      handleCommand(input.value);
      input.value = '';
    } else if(e.key === 'ArrowUp'){
      e.preventDefault();
      if(hIndex > 0){ hIndex--; input.value = history[hIndex]; }
    } else if(e.key === 'ArrowDown'){
      e.preventDefault();
      if(hIndex < history.length - 1){ hIndex++; input.value = history[hIndex]; }
      else { hIndex = history.length; input.value = ''; }
    } else if(e.key === 'Tab'){
      e.preventDefault();
      const match = cmdList.find(c => c.startsWith(input.value.toLowerCase()));
      if(match) input.value = match;
    }
  });

  document.querySelectorAll('.hint kbd').forEach(k => {
    k.style.cursor = 'pointer';
    k.addEventListener('click', () => { handleCommand(k.textContent); input.focus(); });
  });

  term.addEventListener('click', () => input.focus());
  window.addEventListener('load', () => input.focus());
</script>

</body>
</html>
