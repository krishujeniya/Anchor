
// ANCHOR Dashboard Logic

const Elements = {
  project: document.getElementById("project-name"),
  commit: document.getElementById("last-commit"),
  statusText: document.getElementById("status-text"),
  statusDot: document.getElementById("status-dot"),
  gate: document.getElementById("current-gate"),
  milestone: document.getElementById("current-milestone"),
  
  iterVal: document.getElementById("iteration-val"),
  iterCap: document.getElementById("iteration-cap"),
  iterProg: document.getElementById("iteration-progress"),
  
  tokVal: document.getElementById("tokens-val"),
  tokBudget: document.getElementById("tokens-budget"),
  tokProg: document.getElementById("tokens-progress"),
  
  strikeVal: document.getElementById("strikes-val"),
  strikeDots: document.querySelectorAll(".strike-dot"),
  
  skillsList: document.getElementById("skills-list"),
  lastUpdated: document.getElementById("last-updated"),
  hitlCount: document.getElementById("hitl-count"),
  
  telemetryBody: document.getElementById("telemetry-tbody")
};

// Tab Switching
document.querySelectorAll(".nav-item").forEach(item => {
  item.addEventListener("click", (e) => {
    e.preventDefault();
    document.querySelectorAll(".nav-item").forEach(nav => nav.classList.remove("active"));
    document.querySelectorAll(".tab-content").forEach(tab => tab.classList.remove("active"));
    
    e.target.classList.add("active");
    const targetId = e.target.getAttribute("data-tab");
    document.getElementById(targetId).classList.add("active");
  });
});

async function fetchState() {
  try {
    const res = await fetch("../.agents/state/state.json?t=" + new Date().getTime());
    if (!res.ok) throw new Error("state.json not found");
    const state = await res.json();
    updateDashboard(state);
  } catch (err) {
    console.error("Failed to load state:", err);
    Elements.project.innerText = "Error loading project state";
    Elements.statusDot.className = "dot error";
    Elements.statusText.innerText = "ERROR";
  }
}

function updateDashboard(state) {
  Elements.project.innerText = state.project || "ANCHOR Project";
  Elements.commit.innerText = (state.last_known_commit || "Unknown").substring(0, 7);
  Elements.gate.innerText = state.current_gate || "IDLE";
  Elements.milestone.innerText = state.current_milestone || "None";
  
  // Status logic
  if (!state.current_gate || state.current_gate === "IDLE") {
    Elements.statusDot.className = "dot idle";
    Elements.statusText.innerText = "IDLE";
  } else {
    Elements.statusDot.className = "dot active";
    Elements.statusText.innerText = "RUNNING";
  }
  
  // Iteration Math
  Elements.iterVal.innerText = state.iteration || 0;
  Elements.iterCap.innerText = state.iteration_cap || 10;
  const iterPercent = Math.min(100, ((state.iteration || 0) / (state.iteration_cap || 10)) * 100);
  Elements.iterProg.style.width = iterPercent + "%";
  if (iterPercent > 90) Elements.iterProg.style.background = "var(--danger)";
  else if (iterPercent > 70) Elements.iterProg.style.background = "var(--warning)";
  else Elements.iterProg.style.background = "var(--accent-color)";

  // Tokens Math
  Elements.tokVal.innerText = (state.tokens_used || 0).toLocaleString();
  Elements.tokBudget.innerText = (state.token_budget || 0).toLocaleString();
  const tokPercent = Math.min(100, ((state.tokens_used || 0) / (state.token_budget || 1)) * 100);
  Elements.tokProg.style.width = tokPercent + "%";
  if (tokPercent > 90) Elements.tokProg.style.background = "var(--danger)";
  else if (tokPercent > 70) Elements.tokProg.style.background = "var(--warning)";
  else Elements.tokProg.style.background = "var(--accent-color)";

  // Strikes
  const strikes = state.no_progress_strikes || 0;
  Elements.strikeVal.innerText = strikes;
  Elements.strikeDots.forEach((dot, index) => {
    if (index < strikes) dot.classList.add("filled");
    else dot.classList.remove("filled");
  });

  // Environment
  const updatedDate = new Date(state.last_updated);
  Elements.lastUpdated.innerText = isNaN(updatedDate) ? state.last_updated : updatedDate.toLocaleString();
  Elements.hitlCount.innerText = Object.keys(state.hitl_approvals || {}).length;

  // Skills
  if (state.skill_versions) {
    Elements.skillsList.innerHTML = "";
    Object.entries(state.skill_versions).forEach(([name, version]) => {
      const li = document.createElement("li");
      li.innerHTML = `<span class="skill-name">${name}</span><span class="skill-version">v${version}</span>`;
      Elements.skillsList.appendChild(li);
    });
  }
}

async function fetchTelemetry() {
  try {
    const res = await fetch("../.agents/state/telemetry.jsonl?t=" + new Date().getTime());
    if (!res.ok) throw new Error("telemetry.jsonl not found");
    const text = await res.text();
    const lines = text.split("\n").filter(l => l.trim() !== "");
    
    Elements.telemetryBody.innerHTML = "";
    if (lines.length === 0) {
      Elements.telemetryBody.innerHTML = "<tr><td colspan='5'>No telemetry data available.</td></tr>";
      return;
    }
    
    let totalRuns = 0;
    let totalTokens = 0;
    
    lines.reverse().forEach(line => {
      try {
        const data = JSON.parse(line);
        totalRuns++;
        totalTokens += data.tokens_used || 0;
        
        const tr = document.createElement("tr");
        const statusClass = data.status === "COMPLETE" ? "complete" : (data.status === "HALT" ? "halt" : "running");
        const avg = data.iteration > 0 ? Math.round(data.tokens_used / data.iteration) : 0;
        
        tr.innerHTML = `
          <td><strong>${data.milestone}</strong></td>
          <td><span class="status-badge ${statusClass}">${data.status}</span></td>
          <td>${data.iteration}</td>
          <td>${data.tokens_used.toLocaleString()}</td>
          <td>~${avg.toLocaleString()}</td>
        `;
        Elements.telemetryBody.appendChild(tr);
      } catch(e) {
        console.warn("Malformed telemetry row:", line);
        const errTr = document.createElement("tr");
        errTr.innerHTML = `<td colspan="5" style="color:var(--danger)">⚠️ Malformed telemetry row detected</td>`;
        Elements.telemetryBody.appendChild(errTr);
      }
    });
    
    // Update Aggregation Cards
    const aggRuns = document.getElementById("agg-runs");
    const aggTokens = document.getElementById("agg-tokens");
    const aggAvgTokens = document.getElementById("agg-avg-tokens");
    
    if (aggRuns) aggRuns.innerText = totalRuns.toLocaleString();
    if (aggTokens) aggTokens.innerText = totalTokens.toLocaleString();
    if (aggAvgTokens) aggAvgTokens.innerText = totalRuns > 0 ? Math.floor(totalTokens / totalRuns).toLocaleString() : 0;
    
  } catch (err) {
    console.error("Failed to load telemetry:", err);
    Elements.telemetryBody.innerHTML = "<tr><td colspan='5'>Failed to load telemetry data.</td></tr>";
  }
}

// Polling
fetchState();
fetchTelemetry();
setInterval(() => {
  fetchState();
  fetchTelemetry();
}, 2000);
