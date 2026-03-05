<template>
    <div class="mt-4 p-5 bg-light text-black rounded --bs-gray-500">
        <h1> {{club.club_name}}</h1>
        <p><strong>Alte Nume: </strong>{{ club.alternative_club_names?.join(',')}}</p>
        <p><strong>Teritoriu: </strong>{{club.territory}}</p>
        <p><strong>Reprezentant: </strong>{{club.representative}}</p>
        <hr class="my-4">
        <p><strong>Email: </strong>{{club.email}}</p>
        <p><strong>Telefon: </strong>{{club.phone}}</p>
        <p><strong>Numarul de sportivi: </strong><a :href="`/runners?club=${club.id}`">{{runners.length}}</a></p>
        <p><strong>Numarul de rezultate: </strong><a :href="`/results?club=${club.id}`">{{results.length}}</a></p>
    </div>
    <div>
        <label for="club" class="form-label">Club dublicat cu:</label>
                            <select id="club_id" v-model="selectedClub" class="custom-select">
                                <option v-for="club in clubsData" :key="club.id" :value="club.id">
                                    {{ club.club_name }}
                                </option>
                            </select>

        Pastreaza acesta?<input v-model="mainClub" type="checkbox" checked/>
        <button class="btn btn-sm btn-success" @click="mergeClub()">Salveaza</button>
        <hr>

    </div>
    <p class="d-inline-flex gap-1">
        <a class="btn btn-primary" data-bs-toggle="collapse" href="#runnersTable" role="button" aria-expanded="false" aria-controls="runnersTable">
            Sportivi
        </a>
    </p>
    <div class="collapse" id="runnersTable">
        <div class="card card-body">
            <RunnersTable :elements="runners" @order="orderRunnerTable"></RunnersTable>
        </div>
    </div>
    <br>
    <p class="d-inline-flex gap-1">
        <a class="btn btn-primary" data-bs-toggle="collapse" href="#resultsTable" role="button" aria-expanded="false" aria-controls="resultsTable">
            Rezultate
        </a>
    </p>
    <div class="collapse" id="resultsTable">
        <div class="card card-body">
            <ResultsTable :elements="results" @order="orderResultTable"></ResultsTable>
        </div>
    </div>
    <p class="lead">
        <button class="btn btn-sm btn-success" @click="editElement(club)">Editeaza</button>
        <button class="btn btn-danger btn-sm" @click="deleteClub(club.id)">Sterge</button>
        <button class="btn btn-secondary btn-sm" @click="goBack()">Înapoi</button>
    </p>
    <Modal ref="modal" :club="modalElement" :isNew="false" @save="updateElement" />
</template>
<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import Modal from './Modal.vue'
import RunnersTable from '../Runner/Table.vue'
import ResultsTable from '../Result/Table.vue'

axios.defaults.headers['X-CSRF-Token'] = document.querySelector('meta[  name="csrf-token"]').getAttribute('content')

const club = ref({})
const modalElement = ref({})
const modal = ref(null)
const runners = ref([])
const results = ref([])
const clubId = ref("")
const runnerSorting = ref({
    "sorting[sort_by]": "id",
    "sorting[direction]": "asc"
})
const resultSorting = ref({
    "sorting[sort_by]": "date",
    "sorting[direction]": "desc"
})

const clubsSorting = ref({
    "sorting[sort_by]": "club_name",
    "sorting[direction]": "asc"
})

const clubsData = ref([])
const mainClub = ref(true)
const selectedClub = ref({})


onMounted(() => {
    clubId.value = window.location.pathname.split('/').pop();
    getData();
    getRunners();
    getResults();
    getClubs();
})

async function getData() {
    const res = await axios.get(`/clubs/${clubId.value}.json`)
    club.value = res.data;
}

async function getRunners() {
    runnerSorting.value["club"] = clubId.value
    const res = await axios.get('/runners.json', { params: runnerSorting.value })
    runners.value = res.data;
}

async function getResults() {
    resultSorting.value["club"] = clubId.value
    const res = await axios.get('/results.json', { params: resultSorting.value })
    results.value = res.data;
}

function orderRunnerTable(sortKey) {
    orderTable(sortKey, runnerSorting)
    getRunners()
}

function orderResultTable(sortKey) {
    orderTable(sortKey, resultSorting)
    getResults()
}

function orderTable(sortKey, filters) {
    const isCurrentSort = filters.value["sorting[sort_by]"] === sortKey;
    const currentDir = filters.value["sorting[direction]"];

    filters.value["sorting[direction]"] = (isCurrentSort && currentDir === "asc") ? "desc" : "asc";
    filters.value["sorting[sort_by]"] = sortKey;
}

function editElement(club) {
    modalElement.value = { ...club }
    modal.value.show()
}

function updateElement(clubData, done) {
    axios.patch(`/clubs/${clubData.id}.json`, { club: clubData }).then(res => {
        club.value = res.data
        done()
    })
}

function deleteClub(id) {
    if (confirm('Esti sigur ca vrei sa stergi aceast club?')) {
        axios.delete(`/clubs/${id}`).then(() => {
            if (document.referrer) {
                window.location = document.referrer;
            } else {
                window.location = "/clubs";
            }
        })
    }
}

function goBack() {
    if (document.referrer) {
        window.location = document.referrer;
    } else {
        window.location = "/clubs";
    }
}

async function getClubs() {
    const res = await axios.get('/clubs.json', { params: clubsSorting.value })
    clubsData.value = res.data;
}

function mergeClub() {
    let mainId = null;
    let mergedId = null;

    mainId = mainClub.value ? clubId.value : selectedClub.value
    mergedId = mainClub.value ? selectedClub.value : clubId.value

    axios.post(`/clubs/merge_clubs/${mainId}`, {merged_club_id: mergedId})

    window.location = `/clubs/${mainId}`;
}
</script>
