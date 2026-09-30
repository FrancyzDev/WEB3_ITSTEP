import { useEffect, useState } from "react";
import web3 from "./lib/web3";
import mediaContract from "./contracts/media_contract";
import lighthouse from '@lighthouse-web3/sdk';

const Media = () => {

    const storageUrl = 'https://notable-bee-ts014.lighthouseweb3.xyz/ipfs/';

    const apiKey = '5be6e6f8.c5cddb2a58b74025827bc64e8e5a38ec';

    const [account, setAccount] = useState('');
    const [fileName, setFileName] = useState('');
    const [file, setFile] = useState(null);
    const [files, setFiles] = useState([]);
    const [loading, setLoading] = useState(false);

    const [error, setError] = useState('');

    const fallbackUrl = 'https://gateway.lighthouse.storage/ipfs/';

    const loadFiles = async () => {
        try {
            const result = await mediaContract.methods.get_files().call();
            console.log("Files from contract: ", result);
            setFiles([...result].reverse());
        } catch (e) {
            console.error("get_files failed: ", e);
            setError("Не удалось прочитать контракт (проверьте адрес в media_contract.js и сеть MetaMask 31337): " + e.message);
        }
    }

    const onImgError = (e) => {
        if (!e.target.src.startsWith(fallbackUrl)) {
            e.target.src = fallbackUrl + e.target.dataset.cid;
        }
    }

    useEffect(() => {
        loadFiles();
        const loadAccounts = async () => {
            const accounts = await web3.eth.getAccounts();
            if (accounts.length > 0) {
                console.log("Accounts: ", accounts);
                setAccount(accounts[0]);
            }
        }

        loadAccounts();
        const handleChangedAccount = (accounts) => {
            console.log("Accounts(handler): ", accounts);
            setAccount(accounts[0]);
        }

        window.ethereum.on("accountsChanged", handleChangedAccount);

        return () => {
            window.ethereum.removeListener("accountsChanged", handleChangedAccount);
        }

    }, [])

    const createFile = async(e)=>{
        e.preventDefault();
        if (!file) return;

        const form = e.target;
        setLoading(true);
        setError('');
        try {
            const uploadedResult = await lighthouse.upload([file], apiKey);
            console.log("Lighthouse result: ", uploadedResult);
            await mediaContract.methods.new_file(uploadedResult.data.Hash, fileName || file.name).send({from: account});

            form.reset();
            setFile(null);
            setFileName('');
            await loadFiles();
        } catch (e) {
            console.error("Upload failed: ", e);
            setError("Ошибка загрузки/транзакции: " + e.message);
        } finally {
            setLoading(false);
        }
    }

    const deleteFile = async(id)=>{
        try {
            await mediaContract.methods.delete_file(id).send({from: account});
            await loadFiles();
        } catch (e) {
            console.error("Delete failed: ", e);
            setError("Ошибка удаления: " + e.message);
        }
    }

    return (
        <div>
            <h1>Account: {account}</h1>
            <form onSubmit={createFile}>
                <input type="text" onChange={(e)=>setFileName(e.target.value)} placeholder="Set name for file"/>
                <input type="file" accept="image/*" onChange={(e)=> setFile(e.target.files[0])} />
                <button type="submit" disabled={loading || !file}>{loading ? "Uploading..." : "Upload file"}</button>
            </form>
            {error && <p style={{color: "red"}}>{error}</p>}
            {files.length === 0 && !error && <p>Файлов в контракте пока нет</p>}

            <div style={{display: "flex", flexWrap: "wrap", gap: 16, marginTop: 24}}>
                {files.map((f)=>(
                    <div key={f.id.toString()} style={{width: 240}}>
                        <img src={`${storageUrl}${f.cid}`} data-cid={f.cid} onError={onImgError} alt={f.name}style={{width: "100%", height: 180, objectFit: "cover"}} />
                        <div><b>{f.name}</b></div>
                        <div title={f.author}>Author: {f.author.slice(0, 6)}...{f.author.slice(-4)}</div>
                        <div>Created: {new Date(Number(f.created_at) * 1000).toLocaleString()}</div>
                        {f.author.toLowerCase() === account.toLowerCase() && (
                            <button onClick={()=>deleteFile(f.id)}>Delete</button>
                        )}
                    </div>
                ))}
            </div>
        </div>
    )
}

export default Media;