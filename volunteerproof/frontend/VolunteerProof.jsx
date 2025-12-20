import { useState, useEffect } from "react";

// VolunteerProof - World Miniapp
// Verify your humanity. Log your impact. Mint your proof.

export default function VolunteerProof() {
  const [isVerified, setIsVerified] = useState(false);
  const [activeTab, setActiveTab] = useState("log");
  const [hours, setHours] = useState("");
  const [organization, setOrganization] = useState("");
  const [description, setDescription] = useState("");
  const [date, setDate] = useState(new Date().toISOString().split("T")[0]);
  const [entries, setEntries] = useState([
    {
      id: 1,
      hours: 4,
      organization: "Red Cross",
      description: "Blood drive support",
      date: "2025-12-10",
      minted: true,
      txHash: "0x1a2b...3c4d"
    },
    {
      id: 2,
      hours: 6,
      organization: "Local Food Bank",
      description: "Holiday meal prep and distribution",
      date: "2025-12-08",
      minted: false,
      txHash: null
    },
    {
      id: 3,
      hours: 3,
      organization: "Animal Shelter",
      description: "Dog walking and socialization",
      date: "2025-12-05",
      minted: true,
      txHash: "0x5e6f...7g8h"
    }
  ]);
  const [isLogging, setIsLogging] = useState(false);
  const [isMinting, setIsMinting] = useState(null);
  const [showSuccess, setShowSuccess] = useState(false);

  const totalHours = entries.reduce((sum, e) => sum + e.hours, 0);
  const mintedHours = entries.filter(e => e.minted).reduce((sum, e) => sum + e.hours, 0);
  const organizations = [...new Set(entries.map(e => e.organization))].length;

  const handleVerify = () => {
    // Simulate World ID verification
    setTimeout(() => setIsVerified(true), 1500);
  };

  const handleLogHours = () => {
    if (!hours || !organization || !description) return;
    setIsLogging(true);
    setTimeout(() => {
      const newEntry = {
        id: Date.now(),
        hours: parseFloat(hours),
        organization,
        description,
        date,
        minted: false,
        txHash: null
      };
      setEntries([newEntry, ...entries]);
      setHours("");
      setOrganization("");
      setDescription("");
      setIsLogging(false);
      setShowSuccess(true);
      setTimeout(() => setShowSuccess(false), 3000);
    }, 1000);
  };

  const handleMint = (id) => {
    setIsMinting(id);
    setTimeout(() => {
      setEntries(entries.map(e => 
        e.id === id ? { ...e, minted: true, txHash: `0x${Math.random().toString(16).slice(2, 10)}...${Math.random().toString(16).slice(2, 6)}` } : e
      ));
      setIsMinting(null);
    }, 2000);
  };

  // Unverified state - World ID prompt
  if (!isVerified) {
    return (
      <div style={styles.container}>
        <div style={styles.verifyCard}>
          <div style={styles.logoContainer}>
            <div style={styles.logo}>
              <svg width="48" height="48" viewBox="0 0 48 48" fill="none">
                <circle cx="24" cy="24" r="22" stroke="#10b981" strokeWidth="4"/>
                <path d="M16 24L22 30L34 18" stroke="#10b981" strokeWidth="4" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
            </div>
          </div>
          <h1 style={styles.verifyTitle}>VolunteerPROOF</h1>
          <p style={styles.verifySubtitle}>Verify your humanity. Log your impact.</p>
          
          <div style={styles.verifyFeatures}>
            <div style={styles.feature}>
              <span style={styles.featureIcon}>🌍</span>
              <span>Prove you're human with World ID</span>
            </div>
            <div style={styles.feature}>
              <span style={styles.featureIcon}>⏱️</span>
              <span>Log volunteer hours on-chain</span>
            </div>
            <div style={styles.feature}>
              <span style={styles.featureIcon}>🏆</span>
              <span>Mint verifiable impact proofs</span>
            </div>
          </div>

          <button style={styles.worldIdBtn} onClick={handleVerify}>
            <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
              <circle cx="12" cy="12" r="10" fill="none" stroke="currentColor" strokeWidth="2"/>
              <circle cx="12" cy="12" r="4" fill="currentColor"/>
            </svg>
            Verify with World ID
          </button>
          
          <p style={styles.verifyNote}>
            Your volunteer hours are verified by your unique human identity.
            <br/>One person. One proof. Real impact.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div style={styles.container}>
      {/* Header */}
      <header style={styles.header}>
        <div style={styles.headerLeft}>
          <div style={styles.smallLogo}>
            <svg width="28" height="28" viewBox="0 0 48 48" fill="none">
              <circle cx="24" cy="24" r="22" stroke="#10b981" strokeWidth="4"/>
              <path d="M16 24L22 30L34 18" stroke="#10b981" strokeWidth="4" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </div>
          <span style={styles.headerTitle}>VolunteerPROOF</span>
        </div>
        <div style={styles.verifiedBadge}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="#10b981">
            <circle cx="12" cy="12" r="10"/>
          </svg>
          Verified Human
        </div>
      </header>

      {/* Stats Dashboard */}
      <div style={styles.statsGrid}>
        <div style={styles.statCard}>
          <p style={styles.statValue}>{totalHours}</p>
          <p style={styles.statLabel}>Total Hours</p>
        </div>
        <div style={styles.statCard}>
          <p style={styles.statValue}>{mintedHours}</p>
          <p style={styles.statLabel}>Hours Minted</p>
        </div>
        <div style={styles.statCard}>
          <p style={styles.statValue}>{organizations}</p>
          <p style={styles.statLabel}>Organizations</p>
        </div>
      </div>

      {/* Tabs */}
      <div style={styles.tabs}>
        <button 
          style={{...styles.tab, ...(activeTab === "log" ? styles.tabActive : {})}}
          onClick={() => setActiveTab("log")}
        >
          Log Hours
        </button>
        <button 
          style={{...styles.tab, ...(activeTab === "history" ? styles.tabActive : {})}}
          onClick={() => setActiveTab("history")}
        >
          History
        </button>
      </div>

      {/* Success Toast */}
      {showSuccess && (
        <div style={styles.toast}>
          ✓ Hours logged successfully!
        </div>
      )}

      {/* Log Hours Form */}
      {activeTab === "log" && (
        <div style={styles.formCard}>
          <h2 style={styles.formTitle}>Log Volunteer Hours</h2>
          
          <div style={styles.inputGroup}>
            <label style={styles.label}>Hours</label>
            <input
              type="number"
              step="0.5"
              min="0.5"
              value={hours}
              onChange={(e) => setHours(e.target.value)}
              placeholder="e.g., 4"
              style={styles.input}
            />
          </div>

          <div style={styles.inputGroup}>
            <label style={styles.label}>Organization</label>
            <input
              type="text"
              value={organization}
              onChange={(e) => setOrganization(e.target.value)}
              placeholder="e.g., Red Cross"
              style={styles.input}
            />
          </div>

          <div style={styles.inputGroup}>
            <label style={styles.label}>Date</label>
            <input
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
              style={styles.input}
            />
          </div>

          <div style={styles.inputGroup}>
            <label style={styles.label}>What did you do?</label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Briefly describe your volunteer work..."
              style={{...styles.input, ...styles.textarea}}
              rows={3}
            />
          </div>

          <button 
            style={{...styles.submitBtn, ...(isLogging ? styles.btnDisabled : {})}}
            onClick={handleLogHours}
            disabled={isLogging || !hours || !organization || !description}
          >
            {isLogging ? "Logging..." : "Log Hours"}
          </button>

          <p style={styles.formNote}>
            Hours are recorded on World Chain and can be minted as verifiable proofs.
          </p>
        </div>
      )}

      {/* History */}
      {activeTab === "history" && (
        <div style={styles.historyContainer}>
          {entries.length === 0 ? (
            <div style={styles.emptyState}>
              <p>No volunteer hours logged yet.</p>
              <button style={styles.linkBtn} onClick={() => setActiveTab("log")}>
                Log your first hours →
              </button>
            </div>
          ) : (
            entries.map((entry) => (
              <div key={entry.id} style={styles.entryCard}>
                <div style={styles.entryHeader}>
                  <div>
                    <h3 style={styles.entryOrg}>{entry.organization}</h3>
                    <p style={styles.entryDate}>{entry.date}</p>
                  </div>
                  <div style={styles.entryHours}>
                    <span style={styles.hoursValue}>{entry.hours}</span>
                    <span style={styles.hoursLabel}>hrs</span>
                  </div>
                </div>
                <p style={styles.entryDesc}>{entry.description}</p>
                <div style={styles.entryFooter}>
                  {entry.minted ? (
                    <div style={styles.mintedBadge}>
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#10b981" strokeWidth="2">
                        <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
                      </svg>
                      Minted
                      <span style={styles.txHash}>{entry.txHash}</span>
                    </div>
                  ) : (
                    <button 
                      style={{...styles.mintBtn, ...(isMinting === entry.id ? styles.btnDisabled : {})}}
                      onClick={() => handleMint(entry.id)}
                      disabled={isMinting === entry.id}
                    >
                      {isMinting === entry.id ? (
                        <>
                          <span style={styles.spinner}></span>
                          Minting...
                        </>
                      ) : (
                        "Mint Proof NFT"
                      )}
                    </button>
                  )}
                </div>
              </div>
            ))
          )}
        </div>
      )}

      {/* Footer */}
      <footer style={styles.footer}>
        <p>Powered by TIME Protocol</p>
        <p style={styles.footerSub}>World Chain • Proof of Humanity</p>
      </footer>
    </div>
  );
}

const styles = {
  container: {
    minHeight: "100vh",
    background: "linear-gradient(180deg, #0a0f1a 0%, #111827 100%)",
    color: "#f8fafc",
    fontFamily: "'Inter', -apple-system, BlinkMacSystemFont, sans-serif",
    padding: "0 0 80px 0",
  },
  
  // Verify Screen
  verifyCard: {
    minHeight: "100vh",
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    justifyContent: "center",
    padding: "40px 24px",
    textAlign: "center",
  },
  logoContainer: {
    marginBottom: "24px",
  },
  logo: {
    width: "80px",
    height: "80px",
    background: "rgba(16, 185, 129, 0.1)",
    borderRadius: "50%",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
  },
  verifyTitle: {
    fontSize: "2rem",
    fontWeight: "700",
    marginBottom: "8px",
    background: "linear-gradient(135deg, #10b981 0%, #34d399 100%)",
    WebkitBackgroundClip: "text",
    WebkitTextFillColor: "transparent",
  },
  verifySubtitle: {
    fontSize: "1rem",
    color: "#94a3b8",
    marginBottom: "32px",
  },
  verifyFeatures: {
    display: "flex",
    flexDirection: "column",
    gap: "16px",
    marginBottom: "40px",
    textAlign: "left",
  },
  feature: {
    display: "flex",
    alignItems: "center",
    gap: "12px",
    fontSize: "0.95rem",
    color: "#cbd5e1",
  },
  featureIcon: {
    fontSize: "1.25rem",
  },
  worldIdBtn: {
    display: "flex",
    alignItems: "center",
    gap: "12px",
    padding: "16px 32px",
    background: "#fff",
    color: "#000",
    border: "none",
    borderRadius: "50px",
    fontSize: "1rem",
    fontWeight: "600",
    cursor: "pointer",
    marginBottom: "24px",
    transition: "transform 0.2s, box-shadow 0.2s",
  },
  verifyNote: {
    fontSize: "0.8rem",
    color: "#64748b",
    lineHeight: "1.5",
    maxWidth: "280px",
  },

  // Header
  header: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    padding: "16px 20px",
    borderBottom: "1px solid #1e293b",
    position: "sticky",
    top: 0,
    background: "rgba(10, 15, 26, 0.95)",
    backdropFilter: "blur(12px)",
    zIndex: 100,
  },
  headerLeft: {
    display: "flex",
    alignItems: "center",
    gap: "10px",
  },
  smallLogo: {
    width: "36px",
    height: "36px",
    background: "rgba(16, 185, 129, 0.1)",
    borderRadius: "50%",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
  },
  headerTitle: {
    fontSize: "1.1rem",
    fontWeight: "700",
    color: "#10b981",
  },
  verifiedBadge: {
    display: "flex",
    alignItems: "center",
    gap: "6px",
    padding: "6px 12px",
    background: "rgba(16, 185, 129, 0.1)",
    border: "1px solid rgba(16, 185, 129, 0.3)",
    borderRadius: "100px",
    fontSize: "0.75rem",
    fontWeight: "600",
    color: "#10b981",
  },

  // Stats
  statsGrid: {
    display: "grid",
    gridTemplateColumns: "repeat(3, 1fr)",
    gap: "12px",
    padding: "20px",
  },
  statCard: {
    background: "#111827",
    border: "1px solid #1e293b",
    borderRadius: "12px",
    padding: "16px",
    textAlign: "center",
  },
  statValue: {
    fontSize: "1.75rem",
    fontWeight: "700",
    color: "#10b981",
    marginBottom: "4px",
  },
  statLabel: {
    fontSize: "0.7rem",
    color: "#64748b",
    textTransform: "uppercase",
    letterSpacing: "0.5px",
  },

  // Tabs
  tabs: {
    display: "flex",
    padding: "0 20px",
    gap: "8px",
    marginBottom: "20px",
  },
  tab: {
    flex: 1,
    padding: "12px",
    background: "transparent",
    border: "1px solid #1e293b",
    borderRadius: "8px",
    color: "#64748b",
    fontSize: "0.875rem",
    fontWeight: "600",
    cursor: "pointer",
    transition: "all 0.2s",
  },
  tabActive: {
    background: "#10b981",
    borderColor: "#10b981",
    color: "#000",
  },

  // Toast
  toast: {
    position: "fixed",
    top: "80px",
    left: "50%",
    transform: "translateX(-50%)",
    background: "#10b981",
    color: "#000",
    padding: "12px 24px",
    borderRadius: "8px",
    fontWeight: "600",
    fontSize: "0.875rem",
    zIndex: 200,
    animation: "slideDown 0.3s ease-out",
  },

  // Form
  formCard: {
    margin: "0 20px",
    padding: "24px",
    background: "#111827",
    border: "1px solid #1e293b",
    borderRadius: "16px",
  },
  formTitle: {
    fontSize: "1.25rem",
    fontWeight: "600",
    marginBottom: "20px",
  },
  inputGroup: {
    marginBottom: "16px",
  },
  label: {
    display: "block",
    fontSize: "0.8rem",
    fontWeight: "600",
    color: "#94a3b8",
    marginBottom: "6px",
    textTransform: "uppercase",
    letterSpacing: "0.5px",
  },
  input: {
    width: "100%",
    padding: "14px 16px",
    background: "#0a0f1a",
    border: "1px solid #1e293b",
    borderRadius: "10px",
    color: "#f8fafc",
    fontSize: "1rem",
    outline: "none",
    transition: "border-color 0.2s",
  },
  textarea: {
    resize: "vertical",
    minHeight: "80px",
  },
  submitBtn: {
    width: "100%",
    padding: "16px",
    background: "#10b981",
    border: "none",
    borderRadius: "10px",
    color: "#000",
    fontSize: "1rem",
    fontWeight: "700",
    cursor: "pointer",
    marginTop: "8px",
    transition: "all 0.2s",
  },
  btnDisabled: {
    opacity: 0.6,
    cursor: "not-allowed",
  },
  formNote: {
    fontSize: "0.75rem",
    color: "#64748b",
    textAlign: "center",
    marginTop: "16px",
  },

  // History
  historyContainer: {
    padding: "0 20px",
    display: "flex",
    flexDirection: "column",
    gap: "12px",
  },
  emptyState: {
    textAlign: "center",
    padding: "60px 20px",
    color: "#64748b",
  },
  linkBtn: {
    background: "none",
    border: "none",
    color: "#10b981",
    fontSize: "0.875rem",
    cursor: "pointer",
    marginTop: "12px",
  },
  entryCard: {
    background: "#111827",
    border: "1px solid #1e293b",
    borderRadius: "12px",
    padding: "16px",
  },
  entryHeader: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "flex-start",
    marginBottom: "12px",
  },
  entryOrg: {
    fontSize: "1rem",
    fontWeight: "600",
    marginBottom: "2px",
  },
  entryDate: {
    fontSize: "0.8rem",
    color: "#64748b",
  },
  entryHours: {
    textAlign: "right",
  },
  hoursValue: {
    fontSize: "1.5rem",
    fontWeight: "700",
    color: "#10b981",
  },
  hoursLabel: {
    fontSize: "0.7rem",
    color: "#64748b",
    marginLeft: "2px",
  },
  entryDesc: {
    fontSize: "0.875rem",
    color: "#94a3b8",
    marginBottom: "12px",
  },
  entryFooter: {
    borderTop: "1px solid #1e293b",
    paddingTop: "12px",
  },
  mintedBadge: {
    display: "flex",
    alignItems: "center",
    gap: "8px",
    fontSize: "0.8rem",
    color: "#10b981",
    fontWeight: "600",
  },
  txHash: {
    color: "#64748b",
    fontFamily: "monospace",
    fontSize: "0.75rem",
    marginLeft: "auto",
  },
  mintBtn: {
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    gap: "8px",
    width: "100%",
    padding: "10px",
    background: "transparent",
    border: "1px solid #10b981",
    borderRadius: "8px",
    color: "#10b981",
    fontSize: "0.875rem",
    fontWeight: "600",
    cursor: "pointer",
    transition: "all 0.2s",
  },
  spinner: {
    width: "14px",
    height: "14px",
    border: "2px solid transparent",
    borderTopColor: "#10b981",
    borderRadius: "50%",
    animation: "spin 0.8s linear infinite",
  },

  // Footer
  footer: {
    textAlign: "center",
    padding: "40px 20px 20px",
    marginTop: "40px",
  },
  footerSub: {
    fontSize: "0.75rem",
    color: "#64748b",
    marginTop: "4px",
  },
};

// Add keyframes via style tag
if (typeof document !== 'undefined') {
  const styleSheet = document.createElement("style");
  styleSheet.textContent = `
    @keyframes spin {
      to { transform: rotate(360deg); }
    }
    @keyframes slideDown {
      from { opacity: 0; transform: translate(-50%, -20px); }
      to { opacity: 1; transform: translate(-50%, 0); }
    }
    input:focus, textarea:focus {
      border-color: #10b981 !important;
    }
    button:hover:not(:disabled) {
      transform: translateY(-1px);
    }
  `;
  document.head.appendChild(styleSheet);
}
