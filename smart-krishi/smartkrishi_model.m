%% Smart Krishi: soil moisture and irrigation model
% Runs a 30 day root zone moisture simulation with threshold based pump
% control, plots it, and exports smartkrishi.csv for the Smart Krishi page.
% Columns: day, moisture (%), pump (0 = off, 1 = on)

clear; clc;

%% Inputs (change these live during the demo)
soil      = "loamy";   % "loamy" | "clay" | "sandy"
tempC     = 27;        % Mandya demo weather
humidity  = 68;        % percent
days      = 30;
dt        = 0.5;       % time step in days
rainProb  = 0.05;      % chance of a light shower per step
rng(26);               % fixed seed so the demo repeats (run SK-026)

%% Soil parameters
switch soil
    case "loamy", fc = 42; thr = 25; drain = 3.0;
    case "clay",  fc = 48; thr = 28; drain = 2.35;
    case "sandy", fc = 34; thr = 20; drain = 3.7;
end

% Evapotranspiration rises with heat and falls with humidity
et = drain * (1 + (tempC - 26) * 0.04) * (1 - (humidity - 60) * 0.006);

%% Simulation
t        = (0:dt:days)';
moisture = zeros(size(t));
pump     = zeros(size(t));
m        = fc * 0.97;

for k = 1:numel(t)
    if m <= thr                       % controller: switch pump on
        pump(k) = 1;
    end
    moisture(k) = m;
    if pump(k)
        m = fc * (0.97 + 0.03 * rand); % irrigation refills root zone
    else
        m = m - et * dt * (0.82 + 0.36 * rand);
        if rand < rainProb
            m = min(fc, m + 2 + 4 * rand);
        end
    end
end

%% Results
fprintf("Soil: %s | Average moisture: %.1f%% | Pump triggers: %d\n", ...
    soil, mean(moisture), sum(pump));

figure("Color", "w", "Name", "Smart Krishi model");
subplot(2,1,1);
plot(t, moisture, "LineWidth", 2, "Color", [0.18 0.75 0.49]); hold on;
yline(thr, "--", sprintf("%d%% trigger", thr), "Color", [0.85 0.71 0.42]);
ylabel("Moisture %"); title("Soil moisture profile"); grid on;
subplot(2,1,2);
stairs(t, pump, "LineWidth", 2, "Color", [0.18 0.75 0.49]);
ylim([-0.1 1.2]); ylabel("Pump"); xlabel("Days");
title("Irrigation trigger events"); grid on;

%% Export for the Smart Krishi page
T = table(t, moisture, pump, 'VariableNames', {'day','moisture','pump'});
writetable(T, "smartkrishi.csv");
disp("Saved smartkrishi.csv. Import it with Import MATLAB CSV on the page.");
