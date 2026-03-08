const commands = [
    {
        name: 'init',
        desc: 'Scaffolds a new project with your chosen architecture, state management, and routing.',
        usage: 'flutter_arch_gen init',
        example: 'flutter_arch_gen init --architecture clean --state bloc',
        details: 'Initializes the core directory structure including lib/core, lib/data, lib/domain, lib/presentation (for Clean Arch). Also sets up GetIt for DI, Dio for Networking, and your selected Router.'
    },
    {
        name: 'feature',
        desc: 'Generates a complete architectural feature module.',
        usage: 'flutter_arch_gen feature <name>',
        example: 'flutter_arch_gen feature auth',
        details: 'Generates all layers for the feature (Domain, Data, Presentation) and automatically registers the dependencies in injection_container.dart and routes in app_router.dart.'
    },
    {
        name: 'model',
        desc: 'Generates a Freezed model for a specific feature.',
        usage: 'flutter_arch_gen model <name> -f <feature>',
        example: 'flutter_arch_gen model User -f auth',
        details: 'Creates a type-safe model using the Freezed package. Includes factory constructors and toJson/fromJson methods.'
    },
    {
        name: 'page',
        desc: 'Generates a StatelessWidget page and registers its route.',
        usage: 'flutter_arch_gen page <name> -f <feature>',
        example: 'flutter_arch_gen page login -f auth',
        details: 'Creates a UI page file and automatically adds the route to the application router.'
    },
    {
        name: 'theme',
        desc: 'Generates a premium Design System and ThemeData.',
        usage: 'flutter_arch_gen theme',
        example: 'flutter_arch_gen theme',
        details: 'Sets up AppColors, AppTheme, and custom ThemeExtensions for Chat or other features. Includes Light and Dark mode configurations.'
    },
    {
        name: 'refactor',
        desc: 'Safely refactors code, such as injecting fields into models.',
        usage: 'flutter_arch_gen refactor model <filename> --name <field>',
        example: 'flutter_arch_gen refactor model user.dart --name age --type int',
        details: 'Uses AST analysis to safely modify existing files without breaking the syntax.'
    },
    {
        name: 'service',
        desc: 'Generates a new API service or data source.',
        usage: 'flutter_arch_gen service <name> -f <feature>',
        example: 'flutter_arch_gen service auth -f auth',
        details: 'Creates a service class that uses the global ApiClient for network requests.'
    },
    {
        name: 'undo',
        desc: 'Rolls back the last successful generation command.',
        usage: 'flutter_arch_gen undo',
        example: 'flutter_arch_gen undo',
        details: 'Reverts file creations and modifications tracked in the history file.'
    },
    {
        name: 'widget',
        desc: 'Generates a reusable UI component.',
        usage: 'flutter_arch_gen widget <name>',
        example: 'flutter_arch_gen widget custom_button',
        details: 'Creates a StatelessWidget with a dedicated styles file if necessary. Ideal for atomic design components.'
    },
    {
        name: 'repository',
        desc: 'Generates a repository interface and implementation.',
        usage: 'flutter_arch_gen repository <name> -f <feature>',
        example: 'flutter_arch_gen repository product -f shop',
        details: 'Generates both the abstract interface in the Domain layer and the concrete implementation in the Data layer for Clean Architecture.'
    },
    {
        name: 'bloc',
        desc: 'Generates BLoC or Cubit files for state management.',
        usage: 'flutter_arch_gen bloc <name> -f <feature>',
        example: 'flutter_arch_gen bloc counter -f dashboard',
        details: 'Creates Bloc, State, and Event files with boilerplate code ready to handle business logic.'
    },
    {
        name: 'screen',
        desc: 'Generates a full-screen feature entry point.',
        usage: 'flutter_arch_gen screen <name>',
        example: 'flutter_arch_gen screen splash',
        details: 'Similar to page but intended for top-level screens. Handles routing registration automatically.'
    },
    {
        name: 'api',
        desc: 'Scaffolds an API integration layer.',
        usage: 'flutter_arch_gen api',
        example: 'flutter_arch_gen api',
        details: 'Sets up a base API client (using Dio), interceptors, and environment-based configuration for networking.'
    },
    {
        name: 'delete',
        desc: 'Safely removes a feature and its registrations.',
        usage: 'flutter_arch_gen delete <feature>',
        example: 'flutter_arch_gen delete legacy_module',
        details: 'Deletes the feature directory and cleans up its entries in injection_container.dart and app_router.dart.'
    },
    {
        name: 'update',
        desc: 'Updates project dependencies to the latest versions.',
        usage: 'flutter_arch_gen update',
        example: 'flutter_arch_gen update',
        details: 'Checks pubspec.yaml and ensures all generator-managed dependencies (like freezed, dio, get_it) are up to date.'
    },
    {
        name: 'list',
        desc: 'Lists all features in the current project.',
        usage: 'flutter_arch_gen list',
        example: 'flutter_arch_gen list',
        details: 'Scans the lib/features directory and displays a summary of generated modules.'
    },
    {
        name: 'doctor',
        desc: 'Checks the health of your project architecture.',
        usage: 'flutter_arch_gen doctor',
        example: 'flutter_arch_gen doctor',
        details: 'Verifies that all required configuration files exist and that DI/Router files are properly formatted.'
    },
    {
        name: 'rename',
        desc: 'Renames a feature and updates all its imports.',
        usage: 'flutter_arch_gen rename <old_name> <new_name>',
        example: 'flutter_arch_gen rename login authentication',
        details: 'Renames the directory and uses a global search-and-replace to fix all import references across the codebase.'
    },
    {
        name: 'migrate',
        desc: 'Migrates an existing project to a different architecture.',
        usage: 'flutter_arch_gen migrate',
        example: 'flutter_arch_gen migrate --target clean',
        details: 'Attempts to restructure your project into the target architecture pattern. Experimental feature.'
    }
];

function populateCommands() {
    const list = document.getElementById('commandList');
    list.innerHTML = '';
    commands.forEach((cmd, index) => {
        const item = document.createElement('div');
        item.className = 'command-item';
        item.innerHTML = `<span>${cmd.name}</span> <i class="ph ph-caret-right"></i>`;
        item.onclick = () => selectCommand(index);
        list.appendChild(item);
    });
}

function selectCommand(index) {
    const cmd = commands[index];
    const detail = document.getElementById('commandDetailContent');

    // Update active state in list
    document.querySelectorAll('.command-item').forEach((el, i) => {
        el.classList.toggle('active', i === index);
    });

    detail.innerHTML = `
        <div class="command-header">
            <span class="cmd-badge">Command</span>
            <h2>flutter_arch_gen ${cmd.name}</h2>
            <p class="cmd-description">${cmd.desc}</p>
        </div>
        <div class="cmd-section">
            <h4>Usage</h4>
            <div class="code-block">
                <code>${cmd.usage}</code>
                <button class="copy-small" onclick="copyText('${cmd.usage}')"><i class="ph ph-copy"></i></button>
            </div>
        </div>
        <div class="cmd-section">
            <h4>Example</h4>
            <div class="code-block alt">
                <code>${cmd.example}</code>
                <button class="copy-small" onclick="copyText('${cmd.example}')"><i class="ph ph-copy"></i></button>
            </div>
        </div>
        <div class="cmd-section">
            <h4>Details</h4>
            <p>${cmd.details}</p>
        </div>
    `;
}

// Number counter animation
function animateValue(obj, start, end, duration) {
    let startTimestamp = null;
    const step = (timestamp) => {
        if (!startTimestamp) startTimestamp = timestamp;
        const progress = Math.min((timestamp - startTimestamp) / duration, 1);
        obj.innerHTML = Math.floor(progress * (end - start) + start);
        if (progress < 1) {
            window.requestAnimationFrame(step);
        }
    };
    window.requestAnimationFrame(step);
}

const observerOptions = {
    threshold: 0.2
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            if (entry.target.id === 'features') {
                document.querySelectorAll('.feature-card').forEach((card, i) => {
                    card.style.animation = `fadeUp 0.6s var(--ease) forwards ${i * 0.1}s`;
                });
            }
            if (entry.target.classList.contains('stats-section')) {
                animateValue(document.getElementById('stat-arch'), 0, 5, 2000);
                animateValue(document.getElementById('stat-cmd'), 0, 19, 2000);
                animateValue(document.getElementById('stat-safe'), 0, 100, 2000);
            }
            observer.unobserve(entry.target);
        }
    });
}, observerOptions);

window.onload = () => {
    populateCommands();
    if (commands.length > 0) selectCommand(0);

    // Set up observers
    const statsSec = document.querySelector('.stats-section');
    if (statsSec) observer.observe(statsSec);

    const featSec = document.querySelector('#features');
    if (featSec) observer.observe(featSec);
};

function filterCommands() {
    const query = document.getElementById('commandSearch').value.toLowerCase();
    const items = document.querySelectorAll('.command-item');
    items.forEach((item, index) => {
        const name = commands[index].name;
        item.style.display = name.includes(query) ? 'flex' : 'none';
    });
}

function scrollToSection(id) {
    document.getElementById(id).scrollIntoView();
}

function copyInstallCommand() {
    copyText('dart pub global activate flutter_architecture_generator');
}

function copyText(text) {
    navigator.clipboard.writeText(text);
    // Simple feedback logic could go here
    console.log('Copied to clipboard:', text);
}
