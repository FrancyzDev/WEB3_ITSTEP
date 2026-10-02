const contract_address = '0x5FbDB2315678afecb367f032d93F642f64180aa3';

let current_account;
let web3;
let contract;

let current_filter = { mode: 'all' };

document.addEventListener('DOMContentLoaded', ()=>{
    const connection_btn = document.getElementById('connection_btn');
    if(connection_btn) connection_btn.addEventListener('click', connectWallet);

    const makePost_btn = document.getElementById('makePost_btn');
    if(makePost_btn) makePost_btn.addEventListener('click', makePost);

    const deleteAll_btn = document.getElementById('deleteAll_btn');
    if(deleteAll_btn) deleteAll_btn.addEventListener('click', deleteAllPosts);

    const showAll_btn = document.getElementById('showAll_btn');
    if(showAll_btn) showAll_btn.addEventListener('click', ()=>{
        current_filter = { mode: 'all' };
        getPosts();
    });

    const showMine_btn = document.getElementById('showMine_btn');
    if(showMine_btn) showMine_btn.addEventListener('click', ()=>{
        current_filter = { mode: 'author', address: current_account };
        getPosts();
    });

    const filterByAuthor_btn = document.getElementById('filterByAuthor_btn');
    if(filterByAuthor_btn) filterByAuthor_btn.addEventListener('click', ()=>{
        const input = document.getElementById('author_filter_input');
        const address = input.value.trim();

        if(!web3 || !web3.utils.isAddress(address)){
            alert("Enter a valid address (0x...)");
            return;
        }

        current_filter = { mode: 'author', address };
        getPosts();
    });

    if(window.ethereum){

        web3 = new Web3(window.ethereum);
        contract = new web3.eth.Contract(abi, contract_address);


        window.ethereum.on("accountsChanged",(accounts)=>{
            if(accounts.length === 0){
                alert("Accounts not found");
                current_account = undefined;
                return;
            }
            current_account = accounts[0];
            enterToDapp();
        })

        subscribeToEvents();
        getPosts();
    }
})

const subscribeToEvents = async()=>{
    try {
        const created = await contract.events.PostCreated({fromBlock: "latest"});
        created.on("data", async(event)=>{
            console.log("Post created: ", event.returnValues);
            await getPosts();
        });

        const deleted = await contract.events.PostDeleted({fromBlock: "latest"});
        deleted.on("data", async(event)=>{
            console.log("Post deleted: ", event.returnValues);
            await getPosts();
        });

        const deletedAll = await contract.events.PostsDeleted({fromBlock: "latest"});
        deletedAll.on("data", async(event)=>{
            console.log("All posts deleted: ", event.returnValues);
            await getPosts();
        });

        const liked = await contract.events.PostLiked({fromBlock: "latest"});
        liked.on("data", async(event)=>{
            console.log("Post like toggled: ", event.returnValues);
            await getPosts();
        });
    } catch (error) {
        console.error("Subscribe error: ", error);
    }
}

const deletePost = async(id)=>{
    try {
        await contract.methods.delete_post(id).send({from: current_account});
    } catch (error) {
        console.error("Delete post error: ", error);
        alert("Delete post error. See logs");
    }
}

const deleteAllPosts = async()=>{
    try {
        if(!confirm("Delete ALL posts?")) return;
        await contract.methods.delete_all_posts().send({from: current_account});
    } catch (error) {
        console.error("Delete all posts error: ", error);
        alert("Delete all posts error. See logs");
    }
}

const toggleLike = async(id)=>{
    try {
        await contract.methods.toggle_like(id).send({from: current_account});
    } catch (error) {
        console.error("Toggle like error: ", error);
        alert("Toggle like error. See logs");
    }
}

const isSameAddress = (a, b)=>{
    return !!a && !!b && a.toLowerCase() === b.toLowerCase();
}

const makePost = async()=>{
    try {
        const post_text = document.getElementById("post_text");
        if(!post_text){
            alert("Post cannot be without text!");
            return;
        }

        const message = post_text.value;

        await contract.methods.create_post(message).send({from: current_account});
        post_text.value = '';
    } catch (error) {
        console.error("Make post error: ", error);
        alert("Make post error. See logs");
    }
}

const connectWallet = async(e)=>{
    if(!window.ethereum){
        alert("Please install web3 provider");
        return;
    }
    try {
        const accounts = await window.ethereum.request({
            method: 'eth_requestAccounts'
        });
        if(!accounts || !Array.isArray(accounts)){
            alert("Accounts not found");
            return;
        }
        if(accounts.length === 0 ){
            alert("Accounts not found")
            return;
        }
        current_account = accounts[0];
        e.target.hidden = true;
        enterToDapp();
    } catch (error) {
        alert("Connect to DApp error. See logs");
        console.error("Connect error: ", error);
    }
}

const enterToDapp = async()=>{
    const account_lbl = document.getElementById('account_lbl');
    account_lbl.hidden = false;
    account_lbl.textContent = current_account;
    account_lbl.style.color = 'darkgreen';

    const dapp = document.getElementById('dapp');
    if(dapp) dapp.hidden = false;

    try {
        const owner = await contract.methods.owner().call();
        const deleteAll_btn = document.getElementById('deleteAll_btn');
        if(deleteAll_btn) deleteAll_btn.hidden = !isSameAddress(owner, current_account);
    } catch (error) {
        console.error("Get owner error: ", error);
    }

    await getPosts();
}

const getPosts = async()=>{
    try{
        const posts = current_filter.mode === 'author'
            ? await contract.methods.get_posts_by_author(current_filter.address).call()
            : await contract.methods.get_posts().call();

        const likedFlags = current_account
            ? await Promise.all(posts.map(post => contract.methods.hasLiked(post.id, current_account).call()))
            : posts.map(()=>false);

        renderFilterStatus();
        renderPosts(posts, likedFlags);
    }catch(error){
        console.error("Get posts error: ", error);
        alert("Trouble with get posts. See logs");
    }
}

const renderFilterStatus = ()=>{
    const status = document.getElementById('filter_status');
    if(!status) return;

    if(current_filter.mode === 'author'){
        const who = isSameAddress(current_filter.address, current_account) ? 'you' : current_filter.address;
        status.textContent = `Showing posts by: ${who}`;
    } else {
        status.textContent = 'Showing: all posts';
    }
}

const renderPosts = (posts, likedFlags)=>{
    const postList = document.getElementById("postList");

    while(postList.firstChild)
        postList.removeChild(postList.firstChild);

    if(posts.length === 0){
        const p = document.createElement('p');
        p.className = 'empty-state';
        p.textContent = "No posts yet";
        postList.appendChild(p);
        return;
    }

    posts.forEach((post, index)=>{
        const card = document.createElement('div');
        card.className = 'post-card';

        const header = document.createElement('div');
        header.className = 'post-header';

        const author = document.createElement('span');
        author.className = 'post-author';
        author.textContent = post.author;
        author.title = 'Click to show only this author\'s posts';
        author.addEventListener('click', ()=>{
            current_filter = { mode: 'author', address: post.author };
            getPosts();
        });

        const time = document.createElement('span');
        time.className = 'post-time';
        time.textContent = new Date(Number(post.timestamp) * 1000).toLocaleString();

        header.appendChild(author);
        header.appendChild(time);

        const content = document.createElement('p');
        content.className = 'post-content';
        content.textContent = post.content;

        const footer = document.createElement('div');
        footer.className = 'post-footer';

        const like_btn = document.createElement('button');
        like_btn.className = 'secondary';
        const liked = !!likedFlags[index];
        if(liked) like_btn.classList.add('liked');
        like_btn.textContent = `${liked ? '💙' : '🤍'} ${post.likeCount}`;
        like_btn.addEventListener('click', ()=>toggleLike(post.id));
        footer.appendChild(like_btn);

        if(isSameAddress(post.author, current_account)){
            const delete_btn = document.createElement('button');
            delete_btn.className = 'danger';
            delete_btn.textContent = "Delete";
            delete_btn.addEventListener('click', ()=>deletePost(post.id));
            footer.appendChild(delete_btn);
        }

        card.appendChild(header);
        card.appendChild(content);
        card.appendChild(footer);

        postList.appendChild(card);
    })
}
