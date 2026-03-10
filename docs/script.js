const commands = [
    {
        name: 'init',
        desc: 'Scaffolds the architectural foundation of your project.',
        usage: 'flutter_arch_gen init',
        example: 'flutter_arch_gen init --architecture clean --state bloc --router go_router',
        details: `Initializes the core directory structure based on your configuration. 
        <br><br><b>What it does:</b>
        <ul>
            <li>Creates <code>lib/core</code> for shared logic, networking, and utilities.</li>
            <li>Scaffolds <code>lib/features</code> as the root for module-based development.</li>
            <li>Generates <code>injection_container.dart</code> for manual Dependency Injection (via GetIt).</li>
            <li>Configures <code>app_router.dart</code> with your chosen routing package.</li>
            <li>Downloads and installs required dependencies (dio, get_it, dartz, etc.).</li>
        </ul>`,
        flags: [
            { name: '--architecture', desc: 'Framework: clean, mvvm, mvc' },
            { name: '--state', desc: 'Options: bloc, cubit, provider, riverpod' },
            { name: '--router', desc: 'Options: go_router, auto_route' }
        ]
    },
    {
        name: 'feature',
        desc: 'Generates a complete architectural module with all layers.',
        usage: 'flutter_arch_gen feature <name>',
        example: 'flutter_arch_gen feature authentication',
        details: `The core command for daily development. It scafolds a feature based on your project's architecture.
        <br><br><b>Clean Architecture Output:</b>
        <ul>
            <li><b>Domain:</b> Entities, Repositories (abstract), Use Cases.</li>
            <li><b>Data:</b> Models, Data Sources, Repository Implementations.</li>
            <li><b>Presentation:</b> Pages, BLoCs/States, Widgets.</li>
        </ul>
        It also automatically registers the feature in your DI container and adds a base route in your router.`,
        flags: [
            { name: '-n, --name', desc: 'Name of the feature (camelCase or snake_case)' },
            { name: '--architecture', desc: 'Override global architecture' }
        ]
    },
    {
        name: 'api',
        desc: 'Advanced scaffolding from API specs (live or local).',
        usage: 'flutter_arch_gen api <name> --url <spec> --feature <target>',
        example: 'flutter_arch_gen api User -u https://api.sample.com/profile -m POST -f auth',
        details: `A production-ready engine that saves hours of boilerplate.
        <br><br><b>Key Capabilities:</b>
        <ul>
            <li><b>Recursive Inference:</b> Detects nested objects and generates separate models/entities for them.</li>
            <li><b>Method Support:</b> Handles GET, POST, PUT, DELETE, and PATCH.</li>
            <li><b>Body Analysis:</b> Pass a sample JSON body via <code>-b</code> to generate request models.</li>
            <li><b>Unified DI:</b> Automatically registers generated services and use-cases.</li>
            <li><b>Auto Testing:</b> Generates mock-based unit tests for the newly created service.</li>
        </ul>`,
        flags: [
            { name: '-u, --url', desc: 'API URL or local file path (file:///...)' },
            { name: '-m, --method', desc: 'HTTP Method (default: GET)' },
            { name: '-b, --body', desc: 'JSON string for request body inference' },
            { name: '-f, --feature', desc: 'Target feature folder for generation' }
        ]
    },
    {
        name: 'model',
        desc: 'Generates a type-safe model for a feature.',
        usage: 'flutter_arch_gen model <name> -f <feature>',
        example: 'flutter_arch_gen model Product -f shop',
        details: `Creates a Model in the Data layer. If using Freezed, it generates the <code>.freezed.dart</code> and <code>.g.dart</code> boilerplate. 
        In Clean Architecture, it also generates a corresponding Entity in the Domain layer and makes the Model extend it.`,
        flags: [
            { name: '-f, --feature', desc: 'Target feature (Required)' },
            { name: '--use-freezed', desc: 'Toggle Freezed generation (default: true)' }
        ]
    },
    {
        name: 'theme',
        desc: 'Generates a premium Design System for your app.',
        usage: 'flutter_arch_gen theme',
        example: 'flutter_arch_gen theme',
        details: `Sets up a complete atomic design system.
        <br><br><b>Includes:</b>
        <ul>
            <li><b>AppColors:</b> HSL-based color tokens with auto-generated shades.</li>
            <li><b>AppTheme:</b> Centralized ThemeData for Light and Dark modes.</li>
            <li><b>Extensions:</b> ThemeExtension support for custom UI components (like Chat bubbles).</li>
        </ul>`,
        flags: []
    },
    {
        name: 'refactor',
        desc: 'Intelligent code modification via AST analysis.',
        usage: 'flutter_arch_gen refactor <type> <target> --name <field>',
        example: 'flutter_arch_gen refactor model user_model.dart --name email --type String',
        details: `Safely injects code into existing files without overriding manual changes. Use this to add fields to models or inject dependencies into BLoCs.`,
        flags: [
            { name: '--name', desc: 'Name of the field/dependency' },
            { name: '--type', desc: 'Data type' }
        ]
    },
    {
        name: 'undo',
        desc: 'Rollback the last generation command.',
        usage: 'flutter_arch_gen undo',
        example: 'flutter_arch_gen undo',
        details: `Mistake-proof your workflow. This command scans the internal history log and reverts the file changes made by the previous command.`,
        flags: []
    },
    {
        name: 'rename',
        desc: 'Global feature renaming with import correction.',
        usage: 'flutter_arch_gen rename <old> <new>',
        example: 'flutter_arch_gen rename cart shopping_cart',
        details: `Renames a feature directory and performs a global search-and-replace for imports and class names associated with that feature.`,
        flags: []
    }
];

function populateCommands() {
    const list = document.getElementById('commandList');
    list.innerHTML = '';
    commands.forEach((cmd, index) => {
        const btn = document.createElement('button');
        btn.className = 'cmd-btn-pro';
        btn.id = `cmd-${cmd.name}`;
        btn.innerHTML = `<span>${cmd.name}</span> <i class="ph ph-caret-right"></i>`;
        btn.onclick = () => selectCommand(index);
        list.appendChild(btn);
    });
}

function selectCommand(index) {
    const cmd = commands[index];
    const detail = document.getElementById('commandDetailContent');

    // Update active state
    document.querySelectorAll('.cmd-btn-pro').forEach((el, i) => {
        el.classList.toggle('active', i === index);
    });

    let flagsHtml = '';
    if (cmd.flags && cmd.flags.length > 0) {
        flagsHtml = `
            <div class="cmd-section">
                <h4>Flags & Options</h4>
                <div class="flags-grid">
                    ${cmd.flags.map(f => `
                        <div class="flag-item">
                            <span class="flag-name">${f.name}</span>
                            <span class="flag-desc">${f.desc}</span>
                        </div>
                    `).join('')}
                </div>
            </div>
        `;
    }

    detail.innerHTML = `
        <div class="command-content-view">
            <div class="cmd-title-row">
                <span class="badge-pro">Command Reference</span>
                <h2>flutter_arch_gen ${cmd.name}</h2>
                <p>${cmd.desc}</p>
            </div>

            <div class="cmd-section">
                <h4>Standard Usage</h4>
                <div class="code-card">
                    <div class="code-header"><span class="dot red"></span><span class="dot yellow"></span><span class="dot green"></span></div>
                    <div class="code-body">
                        <code>${cmd.usage}</code>
                        <button class="copy-btn-inner" onclick="showToastAndCopy('${cmd.usage}')"><i class="ph ph-copy"></i></button>
                    </div>
                </div>
            </div>

            <div class="cmd-section">
                <h4>Pro Example</h4>
                <div class="code-card alt">
                    <div class="code-body">
                        <code class="text-accent">${cmd.example}</code>
                        <button class="copy-btn-inner" onclick="showToastAndCopy('${cmd.example}')"><i class="ph ph-copy"></i></button>
                    </div>
                </div>
            </div>

            <div class="cmd-section">
                <h4>Technical Details</h4>
                <div class="technical-text">${cmd.details}</div>
            </div>

            ${flagsHtml}
        </div>
    `;

    // Add custom styles for the flags in detail
    const style = document.createElement('style');
    style.innerHTML = `
        .flags-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-top: 12px; }
        .flag-item { background: rgba(255,255,255,0.03); padding: 12px; border-radius: 8px; border: 1px solid var(--border); }
        .flag-name { display: block; font-family: var(--font-mono); color: var(--accent); font-size: 0.85rem; font-weight: 700; }
        .flag-desc { font-size: 0.8rem; color: var(--text-dim); }
        .technical-text { line-height: 1.8; color: var(--text-dim); font-size: 0.95rem; }
        .technical-text b { color: var(--text); }
        .technical-text code { background: #000; padding: 2px 6px; border-radius: 4px; color: var(--primary-light); }
        .cmd-section { margin-top: 40px; }
        .cmd-section h4 { text-transform: uppercase; font-size: 0.75rem; letter-spacing: 0.1em; color: var(--primary); margin-bottom: 12px; }
        .copy-btn-inner { background: none; border: none; color: var(--text-dim); cursor: pointer; float: right; transition: 0.2s; }
        .copy-btn-inner:hover { color: white; }
    `;
    detail.appendChild(style);
}

function showToastAndCopy(text) {
    navigator.clipboard.writeText(text);
    const toast = document.getElementById('copy-toast');
    toast.classList.add('show');
    setTimeout(() => toast.classList.remove('show'), 2000);
}

function filterCommands() {
    const query = document.getElementById('commandSearch').value.toLowerCase();
    commands.forEach(cmd => {
        const btn = document.getElementById(`cmd-${cmd.name}`);
        btn.style.display = cmd.name.includes(query) || cmd.desc.toLowerCase().includes(query) ? 'flex' : 'none';
    });
}

function scrollToSection(id) {
    const el = document.getElementById(id);
    if (el) el.scrollIntoView({ behavior: 'smooth' });
}

function copyInstallCommand() {
    showToastAndCopy('dart pub global activate flutter_architecture_generator');
}

// Stats Animation
function animateValue(obj, start, end, duration) {
    let startTimestamp = null;
    const step = (timestamp) => {
        if (!startTimestamp) startTimestamp = timestamp;
        const progress = Math.min((timestamp - startTimestamp) / duration, 1);
        obj.innerHTML = Math.floor(progress * (end - start) + start);
        if (progress < 1) window.requestAnimationFrame(step);
    };
    window.requestAnimationFrame(step);
}

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            if (entry.target.classList.contains('stats-section')) {
                animateValue(document.getElementById('stat-arch'), 0, 5, 1500);
                animateValue(document.getElementById('stat-cmd'), 0, 19, 1500);
                animateValue(document.getElementById('stat-safe'), 0, 100, 1500);
            }
            observer.unobserve(entry.target);
        }
    });
}, { threshold: 0.1 });

window.onload = () => {
    populateCommands();
    if (commands.length > 0) selectCommand(0);

    const stats = document.querySelector('.stats-section');
    if (stats) observer.observe(stats);
};
