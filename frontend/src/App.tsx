import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import { useAccount } from 'wagmi'
import Header from './components/Header'
import Footer from './components/Footer'
import Dashboard from './pages/Dashboard'
import CreateSession from './pages/CreateSession'
import SessionDetail from './pages/SessionDetail'
import Home from './pages/Home'
import './index.css'

export default function App() {
  const { isConnected } = useAccount()

  return (
    <Router>
      <div className="app">
        <Header />
        <main className="main-content">
          <Routes>
            <Route path="/" element={isConnected ? <Dashboard /> : <Home />} />
            <Route path="/create" element={<CreateSession />} />
            <Route path="/session/:id" element={<SessionDetail />} />
          </Routes>
        </main>
        <Footer />
      </div>
    </Router>
  )
}
