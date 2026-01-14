import React, { useState, useEffect } from 'react';
import { Activity, Server, Database, Smartphone, Upload, Trash2, RefreshCw, Cpu, HardDrive, Wifi, FileText } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

const SERVER_URL = "http://localhost:5000";

function App() {
  const [stats, setStats] = useState({ cpu_percent: 0, memory_percent: 0, ip: "Loading..." });
  const [status, setStatus] = useState("disconnected");
  const [dragActive, setDragActive] = useState(false);
  const [uploadStatus, setUploadStatus] = useState("");

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const res = await fetch(`${SERVER_URL}/system/stats`);
        if (res.ok) {
          const data = await res.json();
          setStats(data);
          setStatus("connected");
        } else {
          setStatus("error");
        }
      } catch (e) {
        setStatus("disconnected");
      }
    };
    fetchStats();
    const interval = setInterval(fetchStats, 2000);
    return () => clearInterval(interval);
  }, []);

  const handleUpload = async (files) => {
    const formData = new FormData();
    formData.append('file', files[0]);
    setUploadStatus("Uploading...");
    try {
      const res = await fetch(`${SERVER_URL}/rag/ingest`, { method: 'POST', body: formData });
      const data = await res.json();
      setUploadStatus(res.ok ? `✅ Success: ${data.message}` : `❌ Error: ${data.error}`);
    } catch (e) {
      setUploadStatus(`❌ Network Error: ${e.message}`);
    }
    setTimeout(() => setUploadStatus(""), 4000);
  };

  return (
    <div className="min-h-screen bg-darkBg text-white selection:bg-neonCyan/30 overflow-hidden relative">
      {/* Background Elements */}
      <div className="absolute top-0 left-0 w-full h-96 bg-gradient-to-b from-neonPurple/5 to-transparent pointer-events-none" />
      <div className="absolute top-[-10%] right-[-10%] w-[40rem] h-[40rem] bg-neonCyan/5 rounded-full blur-[100px] pointer-events-none" />
      <div className="absolute bottom-[-10%] left-[-10%] w-[40rem] h-[40rem] bg-neonPurple/5 rounded-full blur-[100px] pointer-events-none" />

      <div className="container mx-auto px-6 py-12 relative z-10 max-w-7xl">

        {/* Header */}
        <header className="flex flex-col md:flex-row justify-between items-start md:items-center mb-16 gap-6">
          <div className="flex items-center gap-4 group">
            <div className="relative">
              <div className={`absolute inset-0 bg-neonCyan blur-lg opacity-20 group-hover:opacity-40 transition-opacity duration-500 rounded-xl`} />
              <div className="w-14 h-14 rounded-xl bg-white/5 border border-white/10 flex items-center justify-center relative z-10 backdrop-blur-md shadow-2xl">
                <Server className="text-neonCyan w-7 h-7" />
              </div>
            </div>
            <div>
              <h1 className="text-4xl font-black tracking-tight text-transparent bg-clip-text bg-gradient-to-r from-white via-white to-white/50">
                POCKETMIND
              </h1>
              <div className="flex items-center gap-2">
                <div className="h-[1px] w-8 bg-neonPurple" />
                <p className="text-xs font-mono text-neonPurple tracking-widest uppercase">Desktop Bridge</p>
              </div>
            </div>
          </div>

          <div className={`px-5 py-2.5 rounded-full border backdrop-blur-md flex items-center gap-3 transition-all duration-300 ${status === 'connected'
              ? 'border-green-500/20 bg-green-500/5 shadow-[0_0_20px_rgba(34,197,94,0.1)]'
              : 'border-red-500/20 bg-red-500/5 shadow-[0_0_20px_rgba(239,68,68,0.1)]'
            }`}>
            <div className="relative flex h-2.5 w-2.5">
              <span className={`animate-ping absolute inline-flex h-full w-full rounded-full opacity-75 ${status === 'connected' ? 'bg-green-400' : 'bg-red-400'}`}></span>
              <span className={`relative inline-flex rounded-full h-2.5 w-2.5 ${status === 'connected' ? 'bg-green-500' : 'bg-red-500'}`}></span>
            </div>
            <span className={`text-sm font-medium tracking-wide ${status === 'connected' ? 'text-green-400' : 'text-red-400'}`}>
              {status === 'connected' ? "SYSTEM OPERATIONAL" : "DISCONNECTED"}
            </span>
          </div>
        </header>

        {/* Dashboard Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">

          {/* Card 1: Mobile Link (QR) */}
          <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5 }} className="glass-panel p-8 rounded-3xl border border-white/5 bg-white/[0.02] relative hover:bg-white/[0.04] transition-colors group">
            <div className="absolute top-0 right-0 p-8 opacity-50 group-hover:opacity-100 transition-opacity">
              <Wifi className="text-neonCyan/20 w-12 h-12" />
            </div>

            <h2 className="text-xl font-bold mb-8 flex items-center gap-3">
              <Smartphone className="text-neonCyan" size={24} />
              <span>Mobile Link</span>
            </h2>

            <div className="flex flex-col items-center">
              <div className="relative p-2 rounded-2xl bg-white mb-6 shadow-[0_0_40px_rgba(0,243,255,0.1)] group-hover:shadow-[0_0_60px_rgba(0,243,255,0.2)] transition-shadow duration-500">
                {stats.ip && stats.ip !== "Loading..." ? (
                  <img src={`https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=http://${stats.ip}:5000`} alt="QR Code" className="w-56 h-56 rounded-xl" />
                ) : (
                  <div className="w-56 h-56 flex flex-col items-center justify-center bg-gray-50 text-gray-400 rounded-xl">
                    <RefreshCw className="animate-spin mb-2" />
                    <span className="text-xs font-mono">CONNECTING...</span>
                  </div>
                )}
              </div>

              <div className="text-center">
                <div className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-white/5 border border-white/5 mb-3 hover:bg-white/10 transition-colors cursor-copy" onClick={() => navigator.clipboard.writeText(`http://${stats.ip}:5000`)}>
                  <span className="font-mono text-neonCyan text-lg">{stats.ip}:5000</span>
                </div>
                <p className="text-gray-500 text-sm">Scan with AI Pocket Mind App</p>
              </div>
            </div>
          </motion.div>

          {/* Card 2: System Health */}
          <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5, delay: 0.1 }} className="glass-panel p-8 rounded-3xl border border-white/5 bg-white/[0.02] flex flex-col">
            <h2 className="text-xl font-bold mb-8 flex items-center gap-3">
              <Activity className="text-neonPurple" size={24} />
              <span>System Health</span>
            </h2>

            <div className="space-y-8 flex-1">
              <div className="space-y-3">
                <div className="flex justify-between items-end">
                  <div className="flex items-center gap-2 text-gray-400">
                    <Cpu size={16} /> <span className="text-sm font-medium">CPU Usage</span>
                  </div>
                  <span className="text-2xl font-bold font-mono">{stats.cpu_percent}%</span>
                </div>
                <div className="h-2 bg-white/5 rounded-full overflow-hidden">
                  <motion.div
                    initial={{ width: 0 }}
                    animate={{ width: `${stats.cpu_percent}%` }}
                    transition={{ type: "spring", stiffness: 50 }}
                    className="h-full bg-gradient-to-r from-neonPurple to-pink-500 relative"
                  >
                    <div className="absolute right-0 top-0 bottom-0 w-2 bg-white/50 blur-[2px]" />
                  </motion.div>
                </div>
              </div>

              <div className="space-y-3">
                <div className="flex justify-between items-end">
                  <div className="flex items-center gap-2 text-gray-400">
                    <HardDrive size={16} /> <span className="text-sm font-medium">Memory Usage</span>
                  </div>
                  <span className="text-2xl font-bold font-mono text-neonCyan">{stats.memory_percent}%</span>
                </div>
                <div className="h-2 bg-white/5 rounded-full overflow-hidden">
                  <motion.div
                    initial={{ width: 0 }}
                    animate={{ width: `${stats.memory_percent}%` }}
                    transition={{ type: "spring", stiffness: 50 }}
                    className="h-full bg-gradient-to-r from-cyan-600 to-neonCyan relative"
                  >
                    <div className="absolute right-0 top-0 bottom-0 w-2 bg-white/50 blur-[2px]" />
                  </motion.div>
                </div>
              </div>

              <div className="mt-auto pt-8">
                <div className="p-4 rounded-2xl bg-gradient-to-br from-green-500/10 to-emerald-500/5 border border-green-500/20">
                  <div className="flex items-start gap-4">
                    <div className="p-2 bg-green-500/20 rounded-lg">
                      <Database size={20} className="text-green-400" />
                    </div>
                    <div>
                      <h4 className="text-green-400 font-bold text-sm mb-1">Vector Engine Active</h4>
                      <p className="text-green-400/60 text-xs leading-relaxed">ChromaDB is running in persistent mode. Knowledge base is ready for queries.</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </motion.div>

          {/* Card 3: Knowledge Base */}
          <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5, delay: 0.2 }} className="glass-panel p-8 rounded-3xl border border-white/5 bg-white/[0.02] flex flex-col">
            <h2 className="text-xl font-bold mb-8 flex items-center gap-3">
              <Database className="text-green-400" size={24} />
              <span>Knowledge Base</span>
            </h2>

            <div
              onClick={() => document.getElementById('file-upload').click()}
              onDragOver={(e) => { e.preventDefault(); setDragActive(true); }}
              onDragLeave={() => setDragActive(false)}
              onDrop={(e) => { e.preventDefault(); setDragActive(false); handleUpload(e.dataTransfer.files); }}
              className={`flex-1 border-2 border-dashed rounded-2xl transition-all duration-300 flex flex-col items-center justify-center p-6 cursor-pointer group relative overflow-hidden ${dragActive
                  ? 'border-neonCyan bg-neonCyan/5 scale-[1.02]'
                  : 'border-white/10 hover:border-white/20 hover:bg-white/5'
                }`}
            >
              <input id="file-upload" type="file" className="hidden" onChange={(e) => handleUpload(e.target.files)} />

              <div className={`p-4 rounded-full bg-white/5 mb-4 group-hover:scale-110 transition-transform duration-300 ${dragActive ? 'bg-neonCyan/20' : ''}`}>
                <Upload className={`w-8 h-8 ${dragActive ? 'text-neonCyan' : 'text-gray-400 group-hover:text-white'}`} />
              </div>

              <p className="text-gray-300 font-medium mb-2">Click or Drag to Upload</p>
              <p className="text-gray-500 text-xs text-center max-w-[200px]">Support for PDF & Text files. Automatically chunked & embedded.</p>

              <AnimatePresence>
                {uploadStatus && (
                  <motion.div
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0 }}
                    className="absolute bottom-4 left-4 right-4 p-3 rounded-xl bg-black/80 backdrop-blur-md border border-white/10 text-center text-sm font-medium shadow-xl"
                  >
                    {uploadStatus}
                  </motion.div>
                )}
              </AnimatePresence>
            </div>

            <div className="mt-8">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-xs font-bold text-gray-500 uppercase tracking-wider">Recent Ingestions</h3>
                <button className="text-xs text-neonCyan hover:underline">View All</button>
              </div>
              <div className="space-y-2">
                {[1, 2, 3].map(i => (
                  <div key={i} className="flex items-center justify-between p-3 rounded-xl bg-white/[0.02] border border-white/5 hover:bg-white/[0.04] transition-colors group">
                    <div className="flex items-center gap-3">
                      <FileText size={16} className="text-neonPurple/70" />
                      <span className="text-sm text-gray-400 group-hover:text-gray-200 transition-colors">research_paper_v{i}.pdf</span>
                    </div>
                    <Trash2 size={14} className="text-gray-600 hover:text-red-400 cursor-pointer transition-colors opacity-0 group-hover:opacity-100" />
                  </div>
                ))}
              </div>
            </div>
          </motion.div>

        </div>
      </div>
    </div>
  );
}

export default App;
